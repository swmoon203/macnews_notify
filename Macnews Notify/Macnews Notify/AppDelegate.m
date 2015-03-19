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
#import "LazyLoadImageView.h"
#import "DataStore.h"

NSString *const AppNeedLoadDataNotification = @"AppNeedLoadDataNotification";
NSString *const AppNeedReloadHostSettingsNotification = @"AppNeedReloadHostSettingsNotification";

@interface AppDelegate ()

@property (strong, nonatomic) NSDictionary *receivedNotification;
@end

@implementation AppDelegate {
    BOOL _enteredBackground;
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
    
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    
    if (settings.types == UIUserNotificationTypeNone) {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge;
        UIUserNotificationSettings *notifSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:notifSettings];
        
        if ([DataStore sharedData].token != nil) [self afterRegistration:nil];
    }
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

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    if (application.applicationState == UIApplicationStateActive) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
    } else {
        self.receivedNotification = userInfo;
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"performFetchWithCompletionHandler %i", [NSThread isMainThread]);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[DataStore sharedData] updateData:^(NSInteger statusCode, NSUInteger count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(count == 0 ? UIBackgroundFetchResultNoData : UIBackgroundFetchResultNewData);
            });
        }];
    });
}

- (void)handleReceivedNotification {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    if (self.receivedNotification == nil || _enteredBackground == NO) {
        self.receivedNotification = nil;
        return;
    }
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


@end
