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
   context = [XJDeviceContext sharedInstance];
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

@end
