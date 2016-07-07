//
//  RCAppDelegate.m
//  BLEKitRC
//
//  Created by Igor Sales on 2014-09-14.
//  Copyright (c) 2014 IgorSales.ca. All rights reserved.
//

#import "RCAppDelegate.h"
#import <BLEKit/BLEKit.h>

@interface ISAppDelegate() <BLKDevicesViewControllerDelegate, BLKDeviceConnection, UINavigationControllerDelegate>

@property (nonatomic, strong) BLKDevice* device;
@property (nonatomic, strong) BLKDevicesViewController* devicesViewController;

@property (nonatomic, strong) NSDate* lastDisconnectionTS;
@property (nonatomic, weak)   NSTimer* reconnectTimer;

@end

@implementation ISAppDelegate

#pragma mark - Private

- (void)tryToReconnect
{
    self.lastDisconnectionTS = [NSDate date];
    [self reconnectToDevice:self.device];
    self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                           target:self
                                                         selector:@selector(reconnectTimerFired:)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)reconnectToDevice:(BLKDevice*)device
{
    [self.BLKManager detach:self fromDevice:device];
    [self.BLKManager attach:self toDevice:device];
}

- (void)reconnectTimerFired:(NSTimer*)timer
{
    if (self.device) {
        [self tryToReconnect];
    }
}

#pragma mark - BLKDevicesViewControllerDelegate

- (void)devicesViewController:(BLKDevicesViewController *)controller didSelectDevice:(BLKDevice *)device
{
    if (self.device != device) {
        [self.BLKManager detach:self fromDevice:self.device];
        self.device = device;
        [self.BLKManager attach:self toDevice:self.device];
    }

    BOOL shouldPush = NO;

    BLKContainerViewController* cvc = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController* svc = (UISplitViewController*)self.window.rootViewController;
        cvc = ((UINavigationController*)[svc viewControllers][1]).viewControllers[0];
    } else {
        cvc = [controller.storyboard instantiateViewControllerWithIdentifier:@"BLKContainer"];
        cvc.manager = self.BLKManager;
        shouldPush = YES;
    }
    
    BLKConfiguration* cfg = [self.BLKManager deserializedConfigurationForDevice:device];
    if (!cfg) {
        cfg = [BLKConfiguration new];
        cfg.device = device;
    }
    cvc.configuration = device.configuration = cfg;
    
    if (shouldPush) {
        UINavigationController* nvc = (UINavigationController*)self.window.rootViewController;
        [nvc pushViewController:cvc animated:YES];
    }
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.BLKManager = [BLKManager new];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController*      svc = (UISplitViewController*)self.window.rootViewController;
        UINavigationController*     nvc = [svc viewControllers][0];
        BLKDevicesViewController*   dvc = nvc.viewControllers[0];
        BLKContainerViewController* cvc = ((UINavigationController*)[svc viewControllers][1]).viewControllers[0];

        cvc.manager = self.BLKManager;
        dvc.discoveryOperation = [[BLKDiscoveryOperation alloc] initWithManager:self.BLKManager];
        dvc.discoveryOperation.delegate = dvc;
        dvc.manager = self.BLKManager;
        dvc.delegate = self;
        
        self.devicesViewController = dvc;
    } else {
        UINavigationController*     nvc = (UINavigationController*)self.window.rootViewController;
        BLKDevicesViewController*   dvc = nvc.viewControllers[0];
        
        dvc.discoveryOperation = [[BLKDiscoveryOperation alloc] initWithManager:self.BLKManager];
        dvc.discoveryOperation.delegate = dvc;
        dvc.manager = self.BLKManager;
        dvc.delegate = self;
        
        self.devicesViewController = dvc;
        
        nvc.delegate = self;
    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - BLKDeviceConnection

- (void)device:(BLKDevice *)device connectionFailedWithError:(NSError *)error
{
    NSLog(@"BLEKit Device %@ connection failed with error %@", device, error);
}

- (void)deviceAlreadyConnected:(BLKDevice *)device
{
    NSLog(@"BLEKit Device %@ already connected", device);
}

- (void)deviceDidConnect:(BLKDevice *)device
{
    NSLog(@"BLEKit Device %@ connected", device);
    self.lastDisconnectionTS = nil;
    [self.reconnectTimer invalidate];
    self.reconnectTimer = nil;
}

- (void)deviceDidDisconnect:(BLKDevice *)device
{
    NSLog(@"BLEKit Device %@ disconnected", device);

    if (self.device == device) { // the currently connected device
        if (!self.lastDisconnectionTS) {
            [self tryToReconnect];
        }
    }
}

#pragma mark - UINavigationController

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.devicesViewController == viewController) {
        // Just about to show the devices list, so disconnect, if not already
        BLKDevice* device = self.device;
        self.device = nil;
        [self.BLKManager detach:self fromDevice:device];
    }
}

@end
