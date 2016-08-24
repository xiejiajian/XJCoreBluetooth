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

@property (nonatomic, copy) void(^connectSuccessBlock)(XJPeripheral *xjPeripheral);

@property (nonatomic, copy) void(^connectFailureBlock)(NSError *error);

@property (nonatomic, copy) void(^dataReceiveBlock)(id response);

@property (nonatomic, strong) NSCondition *lock;
@property (nonatomic, strong) id response;

@end

@implementation XJDeviceContext {
//    id response;
}

@synthesize connectionState = _connectionState;

//SYNTHESIZE_SINGLETON_FOR_CLASS(XJDeviceContext);

- (instancetype)init {
    self = [super init];
    if (self) {
        _mgr = [XJCentralManager sharedInstance];
        _mgr.autoConnectDelegate = self;
        _lock = [[NSCondition alloc] init];
    }
    
    return self;
}

+ (instancetype)context {
    return [[self alloc] init];
}

- (XJPeripheral *)peripheral {
    if (_peripheral == nil) {
        _peripheral = [_mgr valueForKey:@"targetPeripheral"];
    }
    _peripheral.delegate = self;
    return _peripheral;
}

- (NSMutableArray<XJPeripheral *> *)peripherals {
    return _mgr.peripherals;
}

- (void)setConnectionState:(BOOL)connectionState {
    _connectionState = connectionState;
    
    //POST a notification when state is changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ConnectionStateDidChange" object:@(connectionState) userInfo:nil];
    NSLog(@"state has been change %d",connectionState);
}

- (BOOL)connectionState {
    return [self.peripheral isConnected];
}

- (void)rescan {
    [_mgr rescan];
}

- (void)stopScan {
    [_mgr stopScan];
}

- (void)connectSuccess:(void(^)(XJPeripheral *xjPeripheral))success failure:(void(^)(NSError *error))failure {
    self.peripheral.delegate = self;
    [self.peripheral connect];
    _connectSuccessBlock = success;
    _connectFailureBlock = failure;
}

- (void)disConnect {
    [self.peripheral disConnect];
}

+ (void)utilTaskWithData:(NSData *)data success:(void(^)(id response))success failure:(void(^)(NSError *error))failure {

    XJDeviceContext *context = [XJDeviceContext context];
    [context.peripheral sendToPeripheral:data];
    [context.lock lock];
    [context.lock wait];
    [context.lock unlock];
    
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            success(context.response);
        });
    }
}

- (void)sendData:(NSData *)data success:(void(^)(id response))success {
    [self.peripheral sendToPeripheral:data];

    [_lock lock];
    [_lock wait];
    [_lock unlock];
    
    success(_response);

}

#pragma mark XJPeripheralDelegate
/**
 *  Error:disconnect manually,set notify unsucessfully,system timeout.
 */
- (void)didConnected:(NSError *)error xjPeripheral:(XJPeripheral *)xjPeripheral {
    NSLog(@"Device Context didConnect %@ error %@",xjPeripheral,error);
    self.peripheral = xjPeripheral;
    
    if (error) {
        self.connectionState = NO;
        if (_connectFailureBlock) {
            _connectFailureBlock(error);
        }
    } else {
        self.connectionState = YES;
        if (_connectSuccessBlock) {
            _connectSuccessBlock(xjPeripheral);
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
        [self.peripheral connect];
    }
}

- (void)didReceived:(NSData *)data {
    NSLog(@"Device Context didReceived %@",data);
    
    _response = data;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_lock lock];
        [_lock signal];
        [_lock unlock];

    });
    
}



#pragma mark XJCentralManagerAutoConnectDelegate

- (void)centralManager:(CBCentralManager *)central didAutoConnectXJPeripheral:(XJPeripheral *)peripheral {
    self.peripheral = peripheral;
    self.peripheral.delegate = self;
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
