//
//  RCAppDelegate.h
//  BLEKitRC
//
//  Created by Igor Sales on 2014-09-14.
//  Copyright (c) 2014 IgorSales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BLEKit/BLEKit.h>

@interface ISAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow*   window;
@property (nonatomic, strong) BLKManager* BLKManager;

@end
