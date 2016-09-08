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

static NSString *const BleErrorDomain = @"BleErrorDomain";

@interface XJDeviceContext()<XJCentralManagerAutoConnectDelegate,XJPeripheralDelegate>

@property (nonatomic, strong) XJCentralManager *mgr;

@property (nonatomic, copy) void(^connectSuccessBlock)(XJPeripheral *xjPeripheral);

@property (nonatomic, copy) void(^connectFailureBlock)(NSError *error);

//@property (nonatomic, copy) void(^dataReceiveBlock)(id response);

@property (readwrite, nonatomic, strong) NSCondition *lock;

@property (nonatomic, strong) id response;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, assign) XJCommandQueueType queueType;

@property (nonatomic, assign) BOOL timeout;

@end

@implementation XJDeviceContext

@synthesize connectionState = _connectionState;

SYNTHESIZE_SINGLETON_FOR_CLASS(XJDeviceContext);

- (dispatch_queue_t)serialQueue {
    if (_serialQueue == nil) {
        _serialQueue = dispatch_queue_create("com.datareceive.serialqueue", DISPATCH_QUEUE_SERIAL);
    }
    return _serialQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mgr = [XJCentralManager sharedInstance];
        _mgr.autoConnectDelegate = self;
        _lock = [[NSCondition alloc] init];
        _lock.name = @"com.xj.TransLock";
        _queueType = XJCommandQueueTypeSerial;
    }
    
    return self;
}

//+ (instancetype)context {
//    return [[self alloc] init];
//}

//- (XJPeripheral *)peripheral {
//    if (_peripheral == nil) {
//        _peripheral = [_mgr valueForKey:@"targetPeripheral"];
//    }
//    _peripheral.delegate = self;
//    return _peripheral;
//}

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
    
    XJDeviceContext *context = [XJDeviceContext sharedInstance];
    if (context.queueType == XJCommandQueueTypeSerial) {
        dispatch_async(context.serialQueue, ^{
            [context sendData:data success:success failure:failure];
        });
    } else if (context.queueType == XJCommandQueueTypeConcurrent) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [context sendData:data success:success failure:failure];
        });
    }
    
}

- (void)sendData:(NSData *)data success:(void(^)(id response))success failure:(void(^)(NSError *error))failure {
    [self.peripheral sendToPeripheral:data];
    //长指令发送时，最后一条才获取锁
    _timeout = YES;
    [_lock lock];
    //最多等待10秒
    [_lock waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    [_lock unlock];
    
    __weak __typeof__(self) weakSelf = self;
    if (_timeout) {
        _response = [NSError errorWithDomain:BleErrorDomain code:1006 userInfo:nil];
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(weakSelf.response);
                return ;
            });
        }
        return;
    }
    
    if ([_response isKindOfClass:[NSError class]]) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(weakSelf.response);
                return ;
            });
        }
        return;
        
    } else if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            success(weakSelf.response);
        });
    }
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
    
    //指令已发出，但中途断开，无法接收返回数据。
    [self didReceived:nil];
}

- (void)didReceived:(NSData *)data {
    NSLog(@"Device Context didReceived %@",data);
    
    if (data) {
        _response = data;
        NSLog(@"设备连接正常，数据正常返回");
    } else {
        _response = [NSError errorWithDomain:BleErrorDomain code:1005 userInfo:nil];
        NSLog(@"设备断开，无法返回数据");
    }
    
    //长指令返回，有值才signal。
    __weak __typeof__(self) weakSelf = self;
    if (_response) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            weakSelf.timeout = NO;
            [weakSelf.lock lock];
            [weakSelf.lock signal];
            [weakSelf.lock unlock];
        });
    }
    
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
