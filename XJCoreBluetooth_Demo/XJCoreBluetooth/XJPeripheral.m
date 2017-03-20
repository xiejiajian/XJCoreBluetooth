//
//  XJPeripheral.m
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/21.
//  Copyright © 2016年 xie. All rights reserved.
//

#import "XJPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "XJCentralManager.h"

///the ble status
#define BLE_init                    0x00
#define BLE_scan                    0x01
#define BLE_discovered              0x02
#define BLE_connecting              0x03
#define BLE_discoverServices        0x04
#define BLE_discoverCharacteristics 0x05
#define BLE_updateNotification      0x06
#define BLE_connected               0x07

#define BLE_apduProcessing          0x08
#define BLE_disconnected            0x09

#define BLE_PACKAGE_MAX_SIZE        20

#define CONNECT_XJ_KEY_TIMEOUT  (10.0)

@interface XJPeripheral() <CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager  *centralManager;
@property (nonatomic, strong) CBPeripheral      *peripheral;

@property (nonatomic, strong) CBCharacteristic  *characteristicWriter;
@property (nonatomic, strong) CBCharacteristic  *characteristicReader;
@property (nonatomic, strong) CBService         *service;
@property (nonatomic, strong) NSError           *error;

@property (nonatomic, assign) int discoverCharacteristicCount;
@property (nonatomic, assign) int notifyedCharacteristicCount;
@property (nonatomic, assign) int state;

@end

@implementation XJPeripheral

- (NSString *)version {
    return XJ_PERIPHERAL_VERSION;
}

- (id)initWithDelegate:(id<XJPeripheralDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

- (void)connect {
    if (!_delegate) { return; }
    
    if ([self isConnected]) {
        NSLog(@"peripheral(%@) is connecting", [self name]);
        [_delegate didConnected:nil xjPeripheral:self];
        
    } else {
        NSLog(@"CentralManager initiates the connection to peripheral(%@)", [self name]);
        //        [self clean];
        //        [[SLCentralManager sharedInstance] scanForPeripheral:self];
        //        [SLCentralManager sharedInstance].targetPeripheral = self;
        //        [_centralManager connectPeripheral:_peripheral options:nil];
        //        [_centralManager stopScan];
        [self connectThread];
    }
}

- (void)connectThread {
    [_centralManager connectPeripheral:_peripheral options:nil];
    [self stopWaitingConnectUlanKey];
    [self waitingForConnectUlanKey];
}

- (void)stopWaitingConnectUlanKey {
    [XJCentralManager cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectPeripheralTimeout) object:nil];
}

-(void) waitingForConnectUlanKey
{
    [self performSelector:@selector(connectPeripheralTimeout) withObject:nil afterDelay:CONNECT_XJ_KEY_TIMEOUT];
}

- (void)connectPeripheralTimeout {
    if (![self isConnected]) {
        NSLog(@"centralManager connect timeout");
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"The specified device could be connected timed out over 10s.", NSLocalizedDescriptionKey, nil];
        NSError *error = [NSError errorWithDomain:COM_XJ_PERIPHERAL code:XJ_ERROR_CENTRAL_CONNECT_TIMEOUT userInfo:userInfo];
        [_delegate didConnected:error xjPeripheral:self];
    }
}

- (NSString *)name {
    return _peripheral.name;
}

- (BOOL)isConnected {
    BOOL isConnected = NO;
    if (_peripheral) {
        if ([_peripheral respondsToSelector:@selector(state)]) {
            isConnected = ([[_peripheral valueForKey:@"state"] intValue] == CBPeripheralStateConnected);
        } else if ([_peripheral respondsToSelector:@selector(isConnected)]) {
            isConnected = [[_peripheral valueForKey:@"isConnected"] boolValue];
        }
    }
    return isConnected;
}

//主动断开
- (void)disConnect {
    _error = nil;
    if (_centralManager && _peripheral) {
        [_centralManager cancelPeripheralConnection:_peripheral];
    }
    
    
    //    if ([self isConnected]) {
    //        if (_centralManager) {
    //            [_centralManager cancelPeripheralConnection:_peripheral];
    //        }
    //
    //    }
}

//找到设备，但set Notify失败
- (void)disConnect:(NSError *)error {
    _error = error;
    if (_centralManager && _peripheral) {
        [_centralManager cancelPeripheralConnection:_peripheral];
    }
    
    
    //    if ([self isConnected]) {
    //        if (_centralManager) {
    //            [_centralManager cancelPeripheralConnection:_peripheral];
    //        }
    //
    //    }
}


- (void)clean {
    if (_centralManager && _peripheral) {
        [_centralManager cancelPeripheralConnection:_peripheral];
    }
    
    _centralManager = nil;
    _peripheral = nil;
    
    _characteristicWriter = nil;
    _service = nil;
    _error = nil;
    
    _discoverCharacteristicCount = 0;
    _notifyedCharacteristicCount = 0;
    
    _state = BLE_init;
}



- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Discover target peripheral(%@), description: %@", peripheral.name, peripheral.description);
    //    [central connectPeripheral:peripheral options:nil];
    _centralManager = central;
    _peripheral = peripheral;
    _peripheral.delegate = self;
    _state = BLE_discovered;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverConnectedPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Discover Connected peripheral(%@), description: %@", peripheral.name, peripheral.description);
    [central connectPeripheral:peripheral options:nil];
    _centralManager = central;
    _peripheral = peripheral;
    _peripheral.delegate = self;
    _state = BLE_discovered;
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    //    _peripheral = peripheral;
    //    _peripheral.delegate = self;
    
    _state = BLE_connecting;
    NSLog(@"Connect peripheral(%@) success, description: %@", peripheral.name, peripheral.description);
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:XJ_SERVICE_UUID_TRANSACTION]]];
    _state = BLE_discoverServices;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Connect peripheral(%@) fail, BleError: %@", peripheral.name, error.localizedDescription);
    
    [_delegate didConnected:error xjPeripheral:self];
    [self clean];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (error) {
        NSLog(@"目标外围设备(%@)断开连接, 描述:%@", _peripheral.name, error.localizedDescription);
    } else {
        NSLog(@"中心设备主动断开与外围设备(%@)的连接", _peripheral.name);
    }
    
    switch (_state) {
            //        case BLE_init:
        case BLE_scan:
        case BLE_discovered:
        case BLE_connecting:
        case BLE_discoverServices:
        case BLE_discoverCharacteristics:
            NSLog(@"connect fail, re connect");
            [self connect];
            break;
            
        case BLE_updateNotification:
            if (_error) {
                [_delegate didConnected:_error xjPeripheral:self];
            } else {
                [_delegate didConnected:error xjPeripheral:self];
            }
            break;
            
        case BLE_connected:
        case BLE_apduProcessing:
            _state = BLE_disconnected;
            if (_error) {
                [_delegate didDisConnected:_error];
            } else {
                [_delegate didDisConnected:error];
            }
            
            break;
            
        default:
            [_delegate didDisConnected:error];
            break;
    }
    
    
    
    
    //    if (_state == BLE_connected) {
    //        [_delegate didDisConnected:error];
    //
    //    } else {
    //        if (_error) {
    //            [_delegate didConnected:_error slPeripheral:self];
    //        } else  {
    //            [self connect];
    //        }
    //
    //    }
    //    [self clean];
    _state = BLE_disconnected;
}



- (NSString *)bin2hex:(NSData *)data {
    u_char *pData = NULL; int nDataLength = 0;
    NSMutableString *hexText = nil;
    
    if (data == nil) { nil; }
    
    pData = (u_char *)data.bytes;
    nDataLength = (int)data.length;
    hexText = [[NSMutableString alloc] init];
    
    for (int i = 0; i < nDataLength; i++) {
        [hexText appendFormat:@"%02X ",pData[i]];
    }
    return hexText;
}

- (void)sendToPeripheral:(NSData *)data {
    if (data == nil || data.length == 0) { return; }
    if (_peripheral == nil) { return; }
    
#ifdef DEBUG
    NSString *hex = [self bin2hex:data];
    NSLog(@"tunel(%@) send data(%i): %@", _characteristicWriter.UUID, (int)data.length, hex);
#endif
    
    //    NSLog(@"state %d %d",_state,[self isConnected]);
    
    
    //    if (data.length > BLE_PACKAGE_MAX_SIZE) {
    //        //        NSMutableArray *bleDatas= [NSMutableArray arrayWithCapacity:5];
    //        const char *dataChar=(const char *)data.bytes;
    //        NSMutableArray *ararry = [[NSMutableArray alloc] initWithCapacity:8];
    //        for (int i=0; i<data.length; i+=20) {
    //            int len=20;
    //            if (len >(data.length-i)) {
    //                len=(int)data.length-i;
    //            }
    //            const char * temp= (const char *)&dataChar[i];
    //            NSData *data= [NSData dataWithBytes:temp length:len];
    //            [ararry addObject:data];
    //        }
    //        //        [BLEUtility splitData:data byLength:BLE_PACKAGE_MAX_SIZE intoArarry:bleDatas];
    //        for  (NSData *eachData in ararry ) {
    //            [_peripheral writeValue:eachData forCharacteristic:_characteristicWriter type:CBCharacteristicWriteWithoutResponse];
    //        }
    //    }else{
    [_peripheral writeValue:data forCharacteristic:_characteristicWriter type:CBCharacteristicWriteWithoutResponse];
    
    
}


/*!
 *  @method peripheralDidUpdateName:
 *
 *  @param peripheral	The peripheral providing this update.
 *
 *  @discussion			This method is invoked when the @link name @/link of <i>peripheral</i> changes.
 */
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    
}

/*!
 *  @method peripheral:didModifyServices:
 *
 *  @param peripheral			The peripheral providing this update.
 *  @param invalidatedServices	The services that have been invalidated
 *
 *  @discussion			This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
 *						At this point, the designated <code>CBService</code> objects have been invalidated.
 *						Services can be re-discovered via @link discoverServices: @/link.
 */
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    
}

/*!
 *  @method peripheralDidUpdateRSSI:error:
 *
 *  @param peripheral	The peripheral providing this update.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link readRSSI: @/link call.
 *
 *  @deprecated			Use {@link peripheral:didReadRSSI:error:} instead.
 */
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
}

/*!
 *  @method peripheral:didReadRSSI:error:
 *
 *  @param peripheral	The peripheral providing this update.
 *  @param RSSI			The current RSSI of the link.
 *  @param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link readRSSI: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    
}

/*!
 *  @method peripheral:didDiscoverServices:
 *
 *  @param peripheral	The peripheral providing this information.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
 *						<i>peripheral</i>'s @link services @/link property.
 *
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (error) {
        NSLog(@"peripheral(%@) discover service fail, BleError: %@", peripheral.name, error.localizedDescription);
        [peripheral discoverServices:@[[CBUUID UUIDWithString:XJ_WRITER_CHARACT_UUID_TRANSACTION],[CBUUID UUIDWithString:XJ_READER_CHARACT_UUID_TRANSACTION]]];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        NSLog(@"peripheral(%@) discover service: (%@)", _peripheral.name, service.UUID);
        _service = service;
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:XJ_WRITER_CHARACT_UUID_TRANSACTION],[CBUUID UUIDWithString:XJ_READER_CHARACT_UUID_TRANSACTION]] forService:service];
        
    }
    _discoverCharacteristicCount = 0;
    _notifyedCharacteristicCount = 0;
    _state = BLE_discoverCharacteristics;
    
}

/*!
 *  @method peripheral:didDiscoverIncludedServicesForService:error:
 *
 *  @param peripheral	The peripheral providing this information.
 *  @param service		The <code>CBService</code> object containing the included services.
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
 *						they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error {
    
}

/*!
 *  @method peripheral:didDiscoverCharacteristicsForService:error:
 *
 *  @param peripheral	The peripheral providing this information.
 *  @param service		The <code>CBService</code> object containing the characteristic(s).
 *	@param error		If an error occurred, the cause of the failure.
 *
 *  @discussion			This method returns the result of a @link discoverCharacteristics:forService: @/link call. If the characteristic(s) were read successfully,
 *						they can be retrieved via <i>service</i>'s <code>characteristics</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    if (error) {
        NSLog(@"service(%@) discover Characteristics fail, BleError: %@", service.UUID, error.localizedDescription);
        [peripheral discoverCharacteristics:nil forService:service];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"service(%@) discover Characteristics: (%@)", service.UUID, characteristic.UUID);
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:XJ_WRITER_CHARACT_UUID_TRANSACTION]]) {
            _characteristicWriter = characteristic;
            
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:XJ_READER_CHARACT_UUID_TRANSACTION]]) {
            _characteristicReader = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            _discoverCharacteristicCount++;
        }
        //        else {
        //            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        //            _discoverCharacteristicCount++;
        //        }
    }
    _state = BLE_updateNotification;
    
}


/*!
 *  @method peripheral:didUpdateNotificationStateForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link setNotifyValue:forCharacteristic: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (error) {
        NSLog(@"service(%@) tunnel(%@) notify register fail, BleError: %@", _service.UUID, characteristic.UUID, error.localizedDescription);
        [self disConnect:error];
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"service(%@) tunnel(%@) notify register success", _service.UUID, characteristic.UUID);
        _notifyedCharacteristicCount++;
        if (_notifyedCharacteristicCount == _discoverCharacteristicCount) {
            [_delegate didConnected:nil xjPeripheral:self];
            _state = BLE_connected;
        }
    } else {
        NSLog(@"service(%@) tunnel(%@) notify cancel", _service.UUID, characteristic.UUID);
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"characteristic notify cancel", NSLocalizedDescriptionKey, nil];
        NSError *err = [NSError errorWithDomain:COM_XJ_PERIPHERAL code:XJ_ERROR_DEVICE_DISCONNECT userInfo:userInfo];
        [self disConnect:err];
    }
}


/*!
 *  @method peripheral:didUpdateValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (error) {
        NSLog(@"tunnel(%@) received data fail, BleError: %@", characteristic.UUID, error.localizedDescription);
        [self disConnect:error];
        return;
    }
#ifdef DEBUG
    NSString *hex = [self bin2hex:characteristic.value];
    NSLog(@"tunnel(%@) received data(%i): %@", characteristic.UUID, (int)characteristic.value.length, hex);
#endif
    
    [_delegate didReceived:characteristic.value];
}

/*!
 *  @method peripheral:didWriteValueForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a {@link writeValue:forCharacteristic:type:} call, when the <code>CBCharacteristicWriteWithResponse</code> type is used.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}


/*!
 *  @method peripheral:didDiscoverDescriptorsForCharacteristic:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param characteristic	A <code>CBCharacteristic</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link discoverDescriptorsForCharacteristic: @/link call. If the descriptors were read successfully,
 *							they can be retrieved via <i>characteristic</i>'s <code>descriptors</code> property.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}

/*!
 *  @method peripheral:didUpdateValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link readValueForDescriptor: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
    
}

/*!
 *  @method peripheral:didWriteValueForDescriptor:error:
 *
 *  @param peripheral		The peripheral providing this information.
 *  @param descriptor		A <code>CBDescriptor</code> object.
 *	@param error			If an error occurred, the cause of the failure.
 *
 *  @discussion				This method returns the result of a @link writeValue:forDescriptor: @/link call.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
    
}

@end
