//
//  XJDemoController.m
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/24.
//  Copyright © 2016年 xie. All rights reserved.
//

#import "XJDemoController.h"
#import "XJDeviceContext.h"
#import "XJPeripheral.h"
#import "NSData+BLEHexString.h"
#import "NSString+BLEHexString.h"

@interface XJDemoController ()

@property (weak, nonatomic) IBOutlet UIButton *connectedDevice;
@property (weak, nonatomic) IBOutlet UITextField *sendDataField;
@property (weak, nonatomic) IBOutlet UITextView *dataReceivedView;

@end

@implementation XJDemoController {
    XJDeviceContext *context;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
   context = [XJDeviceContext context];
}

- (IBAction)disconnect:(id)sender {
    [context disConnect];
}

- (IBAction)sendData:(id)sender {
    
    if (_sendDataField.text.length % 2 != 0) {
        NSLog(@"Please input the correct hexadecimal data");
        return;
    }
    
    [XJDeviceContext utilTaskWithData:[NSData dataFromHexString:_sendDataField.text] success:^(NSData *response) {
        _dataReceivedView.text = [NSString hexStringFromData:response];
    } failure:nil];
}

- (IBAction)unwindToDemo:(UIStoryboardSegue *)segue {
    [_connectedDevice setTitle:[NSString stringWithFormat:@"Name\n%@",context.peripheral.name] forState:UIControlStateNormal];
}

- (IBAction)cocurrent:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
        Byte getsn[] = {0xC3,0xC1,0x00};
        NSData *aSetting = [[NSData alloc] initWithBytes:getsn length:sizeof(getsn)];
        [XJDeviceContext utilTaskWithData:aSetting success:^(NSData *response) {
            NSLog(@"c3c100 %@",response);
            
        } failure:nil];
        
        Byte getdate[] = {0x00,0xC0,0x00};
        NSData *bSetting = [[NSData alloc] initWithBytes:getdate length:sizeof(getdate)];
        [XJDeviceContext utilTaskWithData:bSetting success:^(NSData *response) {
            NSLog(@"00c000 %@",response);
        } failure:nil];
        
    });

}


@end
