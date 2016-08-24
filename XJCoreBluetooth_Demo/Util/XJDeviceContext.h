//
//  XJDeviceContext.h
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/24.
//  Copyright © 2016年 xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

typedef NS_ENUM(NSInteger, XJCentralManagerState) {
    XJCentralManagerStateUnsupported  = 0x02,
    XJCentralManagerStatePoweredOff   = 0x04,
    XJCentralManagerStatePoweredOn    = 0x05,
};

@class XJPeripheral;

@interface XJDeviceContext : NSObject

//SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(XJDeviceContext);

/**
 *  The peripheral
 */
@property (nonatomic, strong) XJPeripheral *peripheral;

/**
 *  The peripherals found by scanning.
 */
@property (nonatomic, strong) NSMutableArray<XJPeripheral *> *peripherals;

/**
 *  The state of Central Manager. See more detail in CBCentralManagerState.
 */
@property (nonatomic, assign) XJCentralManagerState managerState;

/**
 *  The current state of connection.
 */
@property (nonatomic, assign) BOOL connectionState;

+ (instancetype)context;

/**
 *  Clean the 'peripherals' array and scan again.
 */
- (void)rescan;

/**
 *  Stop scanning.
 */
- (void)stopScan;

/**
 *  Connect the peripheral you chose from 'peripherals' array.
 *
 *  @param success Returns a XJPeripheral object ,'nil' if failed.
 *  @param failure If failed to connect,returns an NSError.
 */
- (void)connectSuccess:(void(^)(XJPeripheral *xjPeripheral))success failure:(void(^)(NSError *error))failure;
- (void)sendData:(NSData *)data success:(void(^)(id response))success;

/**
 *  cancel the connectinon.
 */
- (void)disConnect;

/**
 *  Write data to the bluetooth device.
 *
 *  @param data    USE NSdata transformed by the Byte[] array.
 *  @param success  Returns a model transformed by NSData.
 *  @param failure 'nil' for now.
 */
+ (void)utilTaskWithData:(NSData *)data success:(void(^)(id response))success failure:(void(^)(NSError *error))failure;

@end
