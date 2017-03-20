//
//  XJPeripheral.h
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/21.
//  Copyright © 2016年 xie. All rights reserved.
//

#import <Foundation/Foundation.h>

#define XJ_SERVICE_UUID_TRANSACTION              @"6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define XJ_WRITER_CHARACT_UUID_TRANSACTION       @"6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define XJ_READER_CHARACT_UUID_TRANSACTION       @"6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define XJ_DFU_SERVICE_UUID_TRANSACTION          @"00001530-1212-EFDE-1523-785FEABCD123"
#define XJ_ANCS_SERVICE_UUID_TRANSACTION         @"7905F431-B5CE-4E99-A40F-4B1E122D00D0"

#define XJ_PERIPHERAL_VERSION                    @"1.0.0.1"

#define BLE_OK      0;
#define BLE_ERROR  -1;

#define XJ_ERROR_CENTRAL_POWEROFF                     0x0000BE00
#define XJ_ERROR_CENTRAL_SCANNING                     0x0000BE01
#define XJ_ERROR_CENTRAL_SCAN_TIMEOUT                 0x0000BE02
#define XJ_ERROR_CENTRAL_CONNECT_TIMEOUT              0x0000BE03

#define XJ_ERROR_DEVICE_FAILCONNECT                   0x0000BE04
#define XJ_ERROR_DEVICE_DISCONNECT                    0x00000007
#define XJ_ERROR_DEVICE_WORKING                       0x0000BE07

@protocol XJCentralManagerDelegate;

@class XJPeripheral;

@protocol XJPeripheralDelegate <NSObject>

- (void)didConnected:(NSError *)error xjPeripheral:(XJPeripheral *)xjPeripheral;

- (void)didDisConnected:(NSError *)error;

- (void)didReceived:(NSData *)data;

@end

@interface XJPeripheral : NSObject<XJCentralManagerDelegate>

@property (nonatomic, assign) id<XJPeripheralDelegate> delegate;

@property (nonatomic, copy) NSString *name;

- (id)initWithDelegate:(id<XJPeripheralDelegate>)delegate;

- (NSString *)version;

- (void)connect;

- (BOOL)isConnected;

- (void)disConnect;

- (void)sendToPeripheral:(NSData *)data;


@end
