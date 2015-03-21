//
//  AppDelegate.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 6..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "MasterViewController.h"
#import <MRProgress/MRProgress.h>

NSString *const AppNeedLoadDataNotification = @"AppNeedLoadDataNotification";
NSString *const AppNeedReloadHostSettingsNotification = @"AppNeedReloadHostSettingsNotification";

@interface AppDelegate ()

@property (strong, nonatomic) NSDictionary *receivedNotification;
@end

@implementation AppDelegate {
    BOOL _enteredBackground;
    CLLocationManager *_locationManager;
    MRProgressOverlayView *_overlayView;
    void(^_onCompleteLocating)();
    int _filterCount;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    
    [self registerDevice];
    _enteredBackground = YES;
    self.receivedNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [self registerLocationService];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self handleReceivedNotification];
    
    _enteredBackground = NO;
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
    _enteredBackground = YES;
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}
//
//- (NSString *)tempDirectory {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//    NSString *cachePath = [paths objectAtIndex:0];
//    BOOL isDir = NO;
//    NSError *error;
//    if (! [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
//        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
//    }
//    return cachePath;
//}
//- (NSURL *)applicationDocumentsDirectory {
//    // The directory the application uses to store the Core Data store file. This code uses a directory named "kr.smoon.ios.Macnews_Notify" in the application's documents directory.
//    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//}

#pragma mark - Notification
- (void)registerDevice {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
   NSArray *actionOptions = @[
                              @{
                                  @"identifier": @"ARCHIVE_IDENTIFIER",
                                  @"title": @"보관",
                                  @"activationMode": @(UIUserNotificationActivationModeBackground),
                                  @"destructive": @NO,
                                  @"authenticationRequired": @NO
                                  },
                              @{
                                  @"identifier": @"REMIND_IDENTIFIER",
                                  @"title": @"나중에",
                                  @"activationMode": @(UIUserNotificationActivationModeBackground),
                                  @"destructive": @NO,
                                  @"authenticationRequired": @NO
                                  },
                              @{
                                  @"identifier": @"DELETE_IDENTIFIER",
                                  @"title": @"삭제",
                                  @"activationMode": @(UIUserNotificationActivationModeBackground),
                                  @"destructive": @YES,
                                  @"authenticationRequired": @NO
                                  }
                              ];
    NSArray *actions = [UIMutableUserNotificationAction userNotificationActionsWith:actionOptions];
    
    
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = @"NEW_ARTICLE";
    [category setActions:actions forContext:UIUserNotificationActionContextDefault];
    
    NSArray *responsiveOption = @[
                                  @[ actions[2], actions[0] ], //보관, 삭제
                                  @[ actions[1], actions[0] ], //보관, 나중에
                                  @[ actions[2], actions[1] ]  //나중에, 삭제
                                  ];
    [category setActions:responsiveOption[[DataStore sharedData].responsiveMode] forContext:UIUserNotificationActionContextMinimal];
    
    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge;
    UIUserNotificationSettings *notifSettings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet setWithObject:category]];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:notifSettings];
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [NSString stringWithFormat:@"%@", deviceToken]; 
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([[DataStore sharedData].userDefaults objectForKey:@"defaultHost"] == nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *url = [NSString stringWithFormat:@"https://push.smoon.kr/v1/devices/%@/registrations/ios.com.tistory.macnews", token];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            request.HTTPMethod = @"POST";
            request.HTTPBody = [[NSString stringWithFormat:@"version=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding];
            NSURLResponse *response = nil;
            NSError *error = nil;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            [[DataStore sharedData].userDefaults setBool:YES forKey:@"defaultHost"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self afterRegistration:token];
            });
        });
    } else {
        [self afterRegistration:token];
    }
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self afterRegistration:nil];
}

- (void)afterRegistration:(NSString *)token {
    if (token != nil && [[DataStore sharedData].token isEqualToString:token] == NO) {
        [[DataStore sharedData].userDefaults setObject:token forKey:@"deviceToken"];
        [[DataStore sharedData].userDefaults synchronize];
    }
    
    NSLog(@"Token ready: %@", [DataStore sharedData].token);
    [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
}

/*
    Remote Notification Event
        Case 1: App Terminated, User tab notification to launch app
            Event: didFinishLaunchingWithOptions: contains info (NSDictionary)
                {
                    UIApplicationLaunchOptionsRemoteNotificationKey: {
                        aps: {
                            alert: {
                                action: "View",
                                title: "...",
                                body: "..."
                            },
                            "url-arg": [
                                "####", <webId>
                            ]
                        }
                    }
                }
 
        Case 2: App in background, User tab notification to bring app foreground
            need to find way
            Event: didReceiveRemoteNotification: contains info (NSDictionary)
                {
                    aps: {
                        alert: {
                            action: "View",
                            title: "...",
                            body: "..."
                        },
                        "url-arg": [
                            "####", <webId>
                        ]
                    }
                }
 
        Case 3: App in foreground, Notification received
            Event: didReceiveRemoteNotification: contains info (NSDictionary)
                {
                    aps: {
                        alert: {
                            action: "View",
                            title: "...",
                            body: "..."
                        },
                    "url-arg": [
                        "####", <webId>
                    ]
                }
 
 */

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    [self application:application handleActionWithIdentifier:identifier userInfo:userInfo completionHandler:completionHandler];
}
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler {
    [self application:application handleActionWithIdentifier:identifier userInfo:notification.userInfo completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier userInfo:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    [[DataStore sharedData] updateData:^(NSManagedObjectContext *context, NSInteger statusCode, NSUInteger count) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
        fetchRequest.fetchLimit = 1;
        fetchRequest.includesPropertyValues = NO;
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"arg == %@ AND webId == %@", userInfo[@"aps"][@"url-args"][0], userInfo[@"aps"][@"url-args"][1]];
        
        NSError *err = nil;
        NSArray *items = [context executeFetchRequest:fetchRequest error:&err];
        if ([items count] > 0) {
            NSManagedObject *item = items[0];
            switch ([@[ @"ARCHIVE_IDENTIFIER", @"REMIND_IDENTIFIER", @"DELETE_IDENTIFIER" ] indexOfObject:identifier]) {
                case 0: //ARCHIVE_IDENTIFIER
                    [item setValue:@YES forKey:@"archived"];
                    [self clearScheduledLocalNotification:userInfo];
                    break;
                case 1: //REMIND_IDENTIFIER
                    [self scheduleNotification:userInfo];
                    break;
                case 2: //DELETE_IDENTIFIER
                    [context deleteObject:item];
                    [self clearScheduledLocalNotification:userInfo];
                    break;
            }
            if (application.applicationIconBadgeNumber > 0) application.applicationIconBadgeNumber--;
            [context save:&err];
        }
        
        dispatch_async(dispatch_get_main_queue(), completionHandler);
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"didReceiveRemoteNotification:%@", userInfo);
    NSLog(@"%li", application.applicationState);
    NSLog(@"UIApplicationStateActive: %li", UIApplicationStateActive);
    NSLog(@"UIApplicationStateInactive: %li", UIApplicationStateInactive);
    NSLog(@"UIApplicationStateBackground: %li", UIApplicationStateBackground);
    if (application.applicationState == UIApplicationStateActive) { //received while running
        [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
        completionHandler(UIBackgroundFetchResultNewData);
    } else if (application.applicationState == UIApplicationStateBackground) { //received while in background
        application.applicationIconBadgeNumber++;
        [self backgroundUpdateData:completionHandler];
    } else { //app opened with notification
        self.receivedNotification = userInfo;
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"performFetchWithCompletionHandler %i", [NSThread isMainThread]);
    
    [self backgroundUpdateData:completionHandler];
}

- (void)backgroundUpdateData:(void (^)(UIBackgroundFetchResult result))completionHandler  {
    [[DataStore sharedData] updateData:^(NSManagedObjectContext *context, NSInteger statusCode, NSUInteger count) {
        [[DataStore sharedData] downloadPreviewImages];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(count == 0 ? UIBackgroundFetchResultNoData : UIBackgroundFetchResultNewData);
        });
    }];
}

- (void)handleReceivedNotification {
    NSLog(@"scheduledLocalNotifications: %@", [[UIApplication sharedApplication] scheduledLocalNotifications]);
    

    //Clear remote notifications and badge number
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    //[[UIApplication sharedApplication] cancelAllLocalNotifications];
    if (self.receivedNotification == nil || _enteredBackground == NO) {
        self.receivedNotification = nil;
        return;
    }
    [self clearScheduledLocalNotification:self.receivedNotification];
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    
    NSArray *args = self.receivedNotification[@"aps"][@"url-args"];
    NSDictionary *item = @{ @"webId": args[1], @"arg": args[0] };
    
    UIViewController *viewController = [navigationController.viewControllers lastObject];
    while ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = [[(UINavigationController *)viewController viewControllers] lastObject];
    }

    [viewController performSegueWithIdentifier:@"notification" sender:item];
    self.receivedNotification = nil;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"openURL:%@", url);
    
    self.receivedNotification = @{ @"aps": @{ @"url-args": @[ url.query, url.host ] } };
    
    return YES;
}

- (void)scheduleNotification:(NSDictionary *)userInfo {
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil) return;
    
    CLLocation *location = [DataStore sharedData].location;
    if ([DataStore sharedData].canUseLocationNotifications &&
        [DataStore sharedData].remindOption == [[DataStore sharedData].remindOptionTitles count] -1 &&
        location != nil) {
        localNotif.regionTriggersOnce = YES;
        
        localNotif.region = [[CLCircularRegion alloc] initWithCenter:location.coordinate
                                                              radius:100
                                                          identifier:@"LOCNOTI"];
    } else {
        localNotif.fireDate = [NSDate dateWithTimeIntervalSinceNow:[DataStore sharedData].remindOptionTimeInterval];
        localNotif.timeZone = [NSTimeZone defaultTimeZone];
    }
    
    localNotif.alertTitle = userInfo[@"aps"][@"alert"][@"title"];
    localNotif.alertBody = userInfo[@"aps"][@"alert"][@"body"];
    localNotif.category = userInfo[@"aps"][@"category"];
    
    localNotif.userInfo = userInfo;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

- (void)clearScheduledLocalNotification:(NSDictionary *)userInfo {
    if (userInfo == nil) return;
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    
    NSArray *args = userInfo[@"aps"][@"url-args"];
    for (UILocalNotification *noti in notifications) {
        NSArray *a = noti.userInfo[@"aps"][@"url-args"];
        if ([args isEqualToArray:a]) {
            NSLog(@"Cancel: %@", noti);
            [[UIApplication sharedApplication] cancelLocalNotification:noti];
        }
    }
}

- (void)registerLocationService {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    [_locationManager requestWhenInUseAuthorization];
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [DataStore sharedData].canUseLocationNotifications = (status == kCLAuthorizationStatusAuthorizedWhenInUse);
}

- (void)detectLocation:(void (^)())onComplete {
    [_locationManager startUpdatingLocation];
    _overlayView = [MRProgressOverlayView showOverlayAddedTo:self.window
                                                       title:@"위치 측정중..."
                                                        mode:MRProgressOverlayViewModeIndeterminate
                                                    animated:YES];
    _onCompleteLocating = onComplete;
    _filterCount = 0;
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    [DataStore sharedData].location = location;
    NSLog(@"%f, %f, %f, %f, %@", location.coordinate.longitude, location.coordinate.latitude, location.horizontalAccuracy, location.verticalAccuracy, location);

    [_overlayView setTitleLabelText:[NSString stringWithFormat:@"위치 측정중...\n%f, %f\n%lim", location.coordinate.longitude, location.coordinate.latitude, (long)location.horizontalAccuracy]];
    _filterCount++;
    
    if (location.horizontalAccuracy <= 65 && _filterCount >= 5) {
        [_overlayView dismiss:YES];
        _overlayView = nil;
        [_locationManager stopUpdatingLocation];
        _onCompleteLocating();
        _onCompleteLocating = nil;
    }
}
@end
