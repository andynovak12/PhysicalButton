//
//  TableViewController.m
//  SimpleControl
//
//  Created by Cheong on 7/11/12.
//  Copyright (c) 2012 RedBearLab. All rights reserved.
//


#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

@synthesize ble;

//- (id)initWithStyle:(UITableViewStyle)style
//{
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

    ble = [[BLE alloc] init];
    [ble controlSetup];
    ble.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - BLE delegate

NSTimer *rssiTimer;

- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");

    [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
    [indConnecting stopAnimating];
    
    
    lblRSSI.text = @"---";
 //   lblAnalogIn.text = @"----";
    
    [rssiTimer invalidate];
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    lblRSSI.text = rssi.stringValue;
}

-(void) readRSSITimer:(NSTimer *)timer
{
    [ble readRSSI];
}

// When disconnected, this will be called
-(void) bleDidConnect
{
    NSLog(@"->Connected");

    [indConnecting stopAnimating];

    
    // send reset
    UInt8 buf[] = {0x04, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [ble write:data];

    // Schedule to read RSSI every 1 sec.
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}

// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"Length: %d", length);

    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3)
    {
        NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);

        if (data[i] == 0x0A)
        {
            if (data[i+1] == 0x01){
                NSLog(@"The button was released!");
                }
            else{
                NSLog(@"This gets called when you push down");
            }
        }
        else if (data[i] == 0x0B)
        {
            UInt16 Value;
            
            Value = data[i+2] | data[i+1] << 8;

        }        
    }
}

#pragma mark - Actions

// Connect button will call to this
- (IBAction)btnScanForPeripherals:(id)sender
{
    if (ble.activePeripheral)
        if(ble.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
            [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
            return;
        }
    
    if (ble.peripherals)
        ble.peripherals = nil;
    
    [btnConnect setEnabled:false];
    [ble findBLEPeripherals:2];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    [indConnecting startAnimating];
}

-(void) connectionTimer:(NSTimer *)timer
{
    [btnConnect setEnabled:true];
    [btnConnect setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    if (ble.peripherals.count > 0)
    {
        [ble connectPeripheral:[ble.peripherals objectAtIndex:0]];
    }
    else
    {
        NSLog(@" HERE Disconnected");
        [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
        [indConnecting stopAnimating];
    }
}


@end
