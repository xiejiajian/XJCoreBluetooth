//
//  XJDeviceContext.m
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/24.
//  Copyright © 2016年 xie. All rights reserved.
//

#import "XJDeviceContext.h"
#import "XJPeripheral.h"
#import "XJCentralManager.h"

@interface XJDeviceContext()<XJCentralManagerAutoConnectDelegate,XJPeripheralDelegate>

@property (nonatomic, strong) XJCentralManager *mgr;

@property (nonatomic, copy) void(^connectSuccessBlock)(XJPeripheral *slPeripheral);

@property (nonatomic, copy) void(^connectFailureBlock)(NSError *error);

@property (nonatomic, copy) void(^dataReceiveBlock)(id response);

@end

@implementation XJDeviceContext

@synthesize connectionState = _connectionState;

SYNTHESIZE_SINGLETON_FOR_CLASS(XJDeviceContext);

- (instancetype)init {
    self = [super init];
    if (self) {
        _mgr = [XJCentralManager sharedInstance];
        _mgr.autoConnectDelegate = self;
    }
    
    return self;
}

- (NSMutableArray<XJPeripheral *> *)peripherals {
    return _mgr.peripherals;
}

- (void)setConnectionState:(BOOL)connectionState {
    _connectionState = connectionState;
    
    //POST a notification when state is changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:ConnectionStateDidChange object:@(connectionState) userInfo:nil];
    NSLog(@"state has been change %d",connectionState);
}

- (BOOL)connectionState {
    return [_peripheral isConnected];
}

- (void)rescan {
    [_mgr rescan];
}

- (void)stopScan {
    [_mgr stopScan];
}

- (void)connectSuccess:(void(^)(XJPeripheral *slPeripheral))success failure:(void(^)(NSError *error))failure {
    _peripheral.delegate = self;
    [_peripheral connect];
    _connectSuccessBlock = success;
    _connectFailureBlock = failure;
}

- (void)disConnect {
    [_peripheral disConnect];
}

+ (void)utilTaskWithData:(NSData *)data success:(void(^)(id response))success failure:(void(^)(NSError *error))failure {
    XJDeviceContext *context = [XJDeviceContext sharedInstance];
    [context.peripheral sendToPeripheral:data];
    context.dataReceiveBlock = success;
}

#pragma mark XJPeripheralDelegate
/**
 *  Error:disconnect manually,set notify unsucessfully,system timeout.
 */
- (void)didConnected:(NSError *)error slPeripheral:(XJPeripheral *)slPeripheral {
    NSLog(@"Device Context didConnect %@ error %@",slPeripheral,error);
    _peripheral = slPeripheral;
    
    if (error) {
        self.connectionState = NO;
        if (_connectFailureBlock) {
            _connectFailureBlock(error);
        }
    } else {
        self.connectionState = YES;
        if (_connectSuccessBlock) {
            _connectSuccessBlock(slPeripheral);
        }
    }
    
    _connectSuccessBlock = nil;
    _connectFailureBlock = nil;
    
}

- (void)didDisConnected:(NSError *)error {
    NSLog(@"Device Context didDisconnect %@",error);
    self.connectionState = NO;
    
    //If system timeout,reconnect.
    if (error) {
        [_peripheral connect];
    }
}

- (void)didReceived:(NSData *)data {
    NSLog(@"Device Context didReceived %@",data);
    
    //Do sth to parser the data.
    id response = data;
    
    if (_dataReceiveBlock) {
        _dataReceiveBlock(response);
    }
}

#pragma mark XJCentralManagerAutoConnectDelegate

- (void)centralManager:(CBCentralManager *)central didAutoConnectSLPeripheral:(XJPeripheral *)peripheral {
    _peripheral = peripheral;
    _peripheral.delegate = self;
}


- (void)centralManager:(CBCentralManager *)central didUpdateState:(NSInteger)state {
    
    switch (state) {
        case XJCentralManagerStateUnsupported:
            _managerState = XJCentralManagerStateUnsupported;
            break;
            
        case XJCentralManagerStatePoweredOff:
            _managerState = XJCentralManagerStatePoweredOff;
            break;
            
        case XJCentralManagerStatePoweredOn:
            _managerState = XJCentralManagerStatePoweredOn;
            break;
            
        default:
            break;
    }
    
}

@end
