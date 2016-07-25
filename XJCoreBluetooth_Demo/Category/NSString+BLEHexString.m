//
//  NSString+BLEHexString.m
//  SLPayDevice
//
//  Created by sl on 16/5/30.
//  Copyright © 2016年 SLZF. All rights reserved.
//

#import "NSString+BLEHexString.h"

@implementation NSString (BLEHexString)

//put data into a byte array (byte[]).
+ (NSString *)hexStringFromData:(NSData *)aData {
    
    Byte *bytes = (Byte *)[aData bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[aData length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    //    NSLog(@"bytes 的16进制数为:%@",hexStr);
    return hexStr;
}

@end
