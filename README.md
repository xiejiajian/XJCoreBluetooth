# XJCoreBluetooth
Based on native coreBluetooth, it provides the interfaces of SENDING and RECEIVING DATA,SCANNING DEVICE,CONNECTION STATE and also can display the scanned device list.

## How to Get Started
run the project "XJCoreBluetooth_Demo.xcodeproj" directly.

## Installation
* Drag the folder "XJCoreBluetooth" to your project.
* Import the header `#import "XJPeripheral.h"`,`#import "XJCentralManager.h"`
* Initialize XJCentralManager `[XJCentralManager sharedInstance]`
* It would be better to create a singleton context like 'XJDeviceContext' *XJDeviceContext is For reference*
