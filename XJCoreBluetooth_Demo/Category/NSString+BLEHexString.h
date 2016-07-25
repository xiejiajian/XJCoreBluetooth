//
//  NSString+BLEHexString.h
//  SLPayDevice
//
//  Created by sl on 16/5/30.
//  Copyright © 2016年 SLZF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BLEHexString)

+ (NSString *)hexStringFromData:(NSData *)aData;

@end
