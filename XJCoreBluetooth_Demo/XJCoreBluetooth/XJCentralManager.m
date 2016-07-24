//
//  XJCentralManager.m
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/21.
//  Copyright © 2016年 xie. All rights reserved.
//

#import "XJCentralManager.h"
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "XJPeripheral.h"

#define SCAN_XJ_KEY_TIMEOUT  (20.0)
#define CONNECT_XJ_KEY_TIMEOUT  (20.0)

@interface XJCentralManager () <CBCentralManagerDelegate,CBPeripheralDelegate>
{
    dispatch_queue_t _bluetoothListenningSerialQueue;
    
}


@property (nonatomic, strong) CBCentralManager *centralManager;

/**
 *  目标设备
 */
@property (nonatomic, strong) XJPeripheral  *targetPeripheral;

/**
 *  连接中的设备
 */
@property (   atomic, strong) NSMutableDictionary *connectedPeripheralsDict;

/**
 *  断开连接的设备
 */
@property (   atomic, strong) NSMutableDictionary *disconnectedPeripheralsDict;

/**
 *  发现的设备
 */
@property (   atomic, strong) NSMutableDictionary *discoverPeripheralsDict;

@property (   atomic, assign) BOOL  isScanning;

@end


@implementation XJCentralManager

SYNTHESIZE_SINGLETON_FOR_CLASS(XJCentralManager);

- (id)init {
    if (self = [super init]) {
        _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue() options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
        _connectedPeripheralsDict = [[NSMutableDictionary alloc] initWithCapacity:7];
        _discoverPeripheralsDict = [[NSMutableDictionary alloc] initWithCapacity:7];
        _disconnectedPeripheralsDict = [[NSMutableDictionary alloc] initWithCapacity:7];
        _peripherals = [NSMutableArray array];
        _targetPeripheral = nil;
        _isScanning = NO;
    }
    
    return self;
    
}

- (int)scanForPeripheral:(XJPeripheral *)xjPeripheral {
    int nResult = BLE_ERROR;
    
    @synchronized (self) {
        
        if (!(_centralManager.state == CBCentralManagerStatePoweredOn || _centralManager.state == CBCentralManagerStateUnknown)) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"中心设备蓝牙关闭csan", NSLocalizedDescriptionKey, nil];
            NSError *error = [NSError errorWithDomain:COM_XJ_PERIPHERAL code:XJ_ERROR_CENTRAL_POWEROFF userInfo:userInfo];
            [xjPeripheral centralManager:nil didFailToConnectPeripheral:nil error:error];
            
            return nResult;
        }
        
        if (_isScanning) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"正在连接其他外围设备", NSLocalizedDescriptionKey, nil];
            NSError *error = [NSError errorWithDomain:COM_XJ_PERIPHERAL code:XJ_ERROR_CENTRAL_SCANNING userInfo:userInfo];
            [xjPeripheral centralManager:nil didFailToConnectPeripheral:nil error:error];
            return nResult;
        }
        
        
        [self scanThread];
        
        //        if (![self scan]) {
        //            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"中心设备正在连接其他外围设备", NSLocalizedDescriptionKey, nil];
        //            NSError *error = [NSError errorWithDomain:COM_SLZF_PERIPHERAL code:SLZF_ERROR_CENTRAL_SCANNING userInfo:userInfo];
        //            [slPeripheral centralManager:nil didFailToConnectPeripheral:nil error:error];
        //            return nResult;
        //        }
        
        //        _targetPeripheral = slPeripheral;
        nResult = BLE_OK;
    }
    
    
    //    nResult = [self setScanState:YES];
    //    if (nResult != 0) {
    //        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"中心设备正在连接其他外围设备", NSLocalizedDescriptionKey, nil];
    //        NSError *error = [NSError errorWithDomain:COM_SLZF_PERIPHERAL code:SLZF_ERROR_CENTRAL_SCANNING userInfo:userInfo];
    //        [slPeripheral centralManager:nil didFailToConnectPeripheral:nil error:error];
    //        return nResult;
    //    }
    
    
_err:
    return nResult;
}



- (void)scanThread
{
    [self performSelector:@selector(scan) withObject:nil afterDelay:0.2];
    [self stopWaitingScanUlanKey];
    [self waitingForScanUlanKey];
}

- (void)stopWaitingScanUlanKey
{
    [XJCentralManager cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanPeripheralTimeout) object:nil];
}

-(void)waitingForScanUlanKey
{
    [self performSelector:@selector(scanPeripheralTimeout) withObject:nil afterDelay:SCAN_XJ_KEY_TIMEOUT];
}

- (void)scanPeripheralTimeout
{
    NSLog(@"centralManager scan timeout");
    [self stopScan];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"The specified device could be connected timed out.", NSLocalizedDescriptionKey, nil];
    NSError *error = [NSError errorWithDomain:COM_XJ_PERIPHERAL code:XJ_ERROR_CENTRAL_SCAN_TIMEOUT userInfo:userInfo];
    [_targetPeripheral centralManager:nil didFailToConnectPeripheral:nil error:error];
}


- (void)scan
{
    
    if (_centralManager.state == CBCentralManagerStatePoweredOn) {
        
        _isScanning = YES;
        NSLog(@"centralManager start scan");
        [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:XJ_SERVICE_UUID_TRANSACTION],[CBUUID UUIDWithString:XJ_DFU_SERVICE_UUID_TRANSACTION]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
        
    }
}

- (void)rescan {
    //    if (self.mgr.delegate == nil) {
    //        self.mgr.delegate = self;
    //    }
    [self stopScan];
    [[self mutableArrayValueForKey:@"peripherals"] removeAllObjects];
    [self scanForPeripheral:nil];
}

- (void)stopScan
{
    NSLog(@"centralManager stop scan");
    _isScanning = NO;
    [_centralManager stopScan];
}


//- (BOOL)scan
//{
//    BOOL nResult = NO;
//
//    @synchronized (self) {
//        if (_isScanning != YES) {
//            [self performSelector:@selector(scanThread) withObject:nil afterDelay:0.2];
//            nResult = YES;
//        }
//    }
//    return nResult;
//}
//
//- (BOOL)stopScan
//{
//    BOOL nResult = NO;
//    @synchronized (self) {
//        if (_isScanning != NO) {
//            _isScanning = NO;
//            [_centralManager stopScan];
//            nResult = YES;
//        } else {
//
//        }
//    }
//    return nResult;
//}







#pragma mark - CBCentralManagerDelegate Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [_autoConnectDelegate centralManager:central didUpdateState:central.state];
    
    //    UlanError *error = nil;
    NSDictionary *userInfo = nil;
    NSError *error = nil;
    NSEnumerator *enumerator = nil;
    NSArray *connectedArr = nil;
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            
            break;
            
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            
            break;
            
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            
            break;
            
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"中心设备蓝牙关闭state", NSLocalizedDescriptionKey, nil];
            error = [NSError errorWithDomain:COM_XJ_PERIPHERAL code:XJ_ERROR_CENTRAL_POWEROFF userInfo:userInfo];
            if (_targetPeripheral) {
                [_targetPeripheral centralManager:nil didFailToConnectPeripheral:nil error:error];
            }
            
            enumerator = [_connectedPeripheralsDict objectEnumerator];
            for (XJPeripheral *up in enumerator) {
                [up centralManager:nil didDisconnectPeripheral:nil error:error];
                
            }
            [_disconnectedPeripheralsDict setDictionary:_connectedPeripheralsDict];
            [_connectedPeripheralsDict removeAllObjects];
            [self stopScan];
            [self stopWaitingScanUlanKey];
            break;
            
        case CBCentralManagerStatePoweredOn:
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            //搜索连接过的设备
            connectedArr =  [central retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:XJ_SERVICE_UUID_TRANSACTION]]];
            if (connectedArr.count) {
                CBPeripheral *p = connectedArr.firstObject;
                NSLog(@"%@",p.name);
                
                [self stopScan];
                _targetPeripheral = [[XJPeripheral alloc] initWithDelegate:nil];
                [_targetPeripheral centralManager:central didDiscoverConnectedPeripheral:p];
                [_disconnectedPeripheralsDict setObject:_targetPeripheral forKey:p.identifier];
            } else {
                [self scanForPeripheral:nil];
            }
            
            //蓝牙开关关闭又重开
            enumerator = [_disconnectedPeripheralsDict objectEnumerator];
            if ([enumerator nextObject]) {
                for (XJPeripheral *up in enumerator) {
                    [up connect];
                }
            }
            
            break;
        default:
            break;
    }
}


- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict
{
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    int nResult = BLE_ERROR;
    
    XJPeripheral *xjPeripheral = [[XJPeripheral alloc] initWithDelegate:nil];
    [_discoverPeripheralsDict setObject:xjPeripheral forKey:peripheral.identifier];
    [xjPeripheral centralManager:central didDiscoverPeripheral:peripheral error:nil];
    
    //KVO
    if (![_peripherals containsObject:xjPeripheral]) {
        [[self mutableArrayValueForKey:@"peripherals"] addObject:xjPeripheral];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //判断
    
    if (_disconnectedPeripheralsDict[peripheral.identifier]) {
        _targetPeripheral = _disconnectedPeripheralsDict[peripheral.identifier];
    } else {
        _targetPeripheral = _discoverPeripheralsDict[peripheral.identifier];
    }
    [_targetPeripheral centralManager:central didConnectPeripheral:peripheral];
    [_autoConnectDelegate centralManager:central didAutoConnectXJPeripheral:_targetPeripheral];
    
    //更新两个字典
    [_connectedPeripheralsDict setObject:_targetPeripheral forKey:peripheral.identifier];
    [_discoverPeripheralsDict removeObjectForKey:peripheral.identifier];
    
    _targetPeripheral = nil;
    
    [self stopScan];
    [self stopWaitingScanUlanKey];
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    [_targetPeripheral centralManager:nil didFailToConnectPeripheral:nil error:error];
    _targetPeripheral = nil;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    XJPeripheral *xjPeripheral = _connectedPeripheralsDict[peripheral.identifier];
    if (xjPeripheral) {
        [xjPeripheral centralManager:central didDisconnectPeripheral:peripheral error:error];
    }
    [_connectedPeripheralsDict removeObjectForKey:peripheral.identifier];
    [_disconnectedPeripheralsDict setObject:xjPeripheral forKey:peripheral.identifier];
}



@end
