//
//  XJCentralManager.h
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/21.
//  Copyright © 2016年 xie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

#define COM_XJ_PERIPHERAL @"com.xj.peripheral"

@class XJPeripheral,CBCentralManager,CBPeripheral;

#pragma mark - CentralManagerDelegate

@protocol XJCentralManagerDelegate<NSObject>

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@optional

- (void)centralManager:(CBCentralManager *)central didDiscoverConnectedPeripheral:(CBPeripheral *)peripheral;

@end

#pragma mark - Auto Connect

@protocol XJCentralManagerAutoConnectDelegate<NSObject>

- (void)centralManager:(CBCentralManager *)central didUpdateState:(NSInteger)state;

- (void)centralManager:(CBCentralManager *)central didAutoConnectXJPeripheral:(XJPeripheral *)peripheral;

@end

#pragma mark - Central Manager definition

@interface XJCentralManager : NSObject

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(XJCentralManager);

@property(nonatomic, assign) id<XJCentralManagerAutoConnectDelegate> autoConnectDelegate;

@property (nonatomic, strong) NSMutableArray<XJPeripheral *> *peripherals;

- (int)scanForPeripheral:(XJPeripheral *)xjPeripheral;

- (void)rescan;

- (void)stopScan;

@end
