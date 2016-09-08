//
//  XJScanController.m
//  XJCoreBluetooth_Demo
//
//  Created by sl on 16/7/24.
//  Copyright © 2016年 xie. All rights reserved.
//

#import "XJScanController.h"
#import "XJDeviceContext.h"
#import "XJPeripheral.h"

@interface XJScanController ()

@property (nonatomic, strong) XJDeviceContext *context;

@end

@implementation XJScanController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _context = [XJDeviceContext sharedInstance];
    
    [_context addObserver:self forKeyPath:@"mgr.peripherals" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    if (_context.managerState == XJCentralManagerStatePoweredOff) {
        NSLog(@"bluetooth is power off");
        [_context rescan];
    }
    
}

- (IBAction)refresh:(id)sender {
    [_context rescan];
}

- (IBAction)back:(id)sender {
    [_context stopScan];
    [self performSegueWithIdentifier:@"unwindToDemo" sender:self];
}


//KVO,update the list.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"mgr.peripherals"]) {
        NSLog(@"%zd peripherals found",_context.peripherals.count);
        NSLog(@"array ==> %@",_context.peripherals);
        [self.tableView reloadData];
    }
}

- (void)dealloc {
    [_context removeObserver:self forKeyPath:@"mgr.peripherals"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _context.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    _context.peripheral = _context.peripherals[indexPath.row];
    cell.textLabel.text = _context.peripheral.name;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.imageView.image = [UIImage imageNamed:@"connect"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    _context.peripheral = _context.peripherals[indexPath.row];
    
    NSLog(@"connecting...");
    [_context connectSuccess:^(XJPeripheral *xjPeripheral) {
        NSLog(@"connect (%@) successfully ",xjPeripheral.name);
        
    } failure:^(NSError *error) {
        NSLog(@"error code => %ld",(long)error.code);
        if (error.code == XJ_ERROR_CENTRAL_CONNECT_TIMEOUT) {
            NSLog(@"connect timeout");
        }
    }];
}



@end
