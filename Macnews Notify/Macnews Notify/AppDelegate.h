//
//  AppDelegate.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 6..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MacnewsCore/MacnewsCore.h>
#import <CoreLocation/CoreLocation.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
- (void)registerDevice;

- (void)clearScheduledLocalNotification:(NSDictionary *)userInfo;
- (void)detectLocation:(void (^)())onComplete;
@end

NSString *const AppNeedLoadDataNotification;
NSString *const AppNeedReloadHostSettingsNotification;