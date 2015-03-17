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

NSString *const AppNeedLoadDataNotification = @"AppNeedLoadDataNotification";
NSString *const AppNeedDataResetNotification = @"AppNeedDataResetNotification";
NSString *const AppNeedReloadHostSettingsNotification = @"AppNeedReloadHostSettingsNotification";

@interface AppDelegate ()
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSMutableArray *hosts;
@property (strong, readonly, nonatomic) NSDictionary *hostsMap;

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
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
    [[NSUserDefaults standardUserDefaults] setObject:_hosts forKey:@"hosts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

- (NSString *)tempDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    NSError *error;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    return cachePath;
}
- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "kr.smoon.ios.Macnews_Notify" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Core Data stack
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) return _managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Macnews_Notify" withExtension:@"momd"];
    return _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) return _persistentStoreCoordinator;
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Macnews_Notify.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) return _managedObjectContext;
    if (self.persistentStoreCoordinator == nil) return nil;
    
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support
- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
- (void)resetContext {
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores lastObject];
    NSError *error;
    NSURL *storeURL = store.URL;
    NSPersistentStoreCoordinator *storeCoordinator = self.persistentStoreCoordinator;
    [storeCoordinator removePersistentStore:store error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
    //    Then, just add the persistent store back to ensure it is recreated properly.
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    _managedObjectContext = nil;
    _managedObjectModel = nil;
    _persistentStoreCoordinator = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedDataResetNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
}

- (NSInteger)idx {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"idx"];
}
- (void)setIdx:(NSInteger)idx {
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:@"idx"];
}
- (void)resetIdx {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"idx"];
}

#pragma mark - Notification
- (void)registerDevice {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    
    if (settings.types == UIUserNotificationTypeNone) {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge;
        UIUserNotificationSettings *notifSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:notifSettings];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"] != nil) [self afterRegistration:nil];
    }
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [NSString stringWithFormat:@"%@", deviceToken]; 
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"defaultHost"] == nil) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *url = [NSString stringWithFormat:@"https://push.smoon.kr/v1/devices/%@/registrations/ios.com.tistory.macnews", token];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            request.HTTPMethod = @"POST";
            request.HTTPBody = [[NSString stringWithFormat:@"version=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding];
            NSURLResponse *response = nil;
            NSError *error = nil;
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"defaultHost"];
            
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
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *key = @"deviceToken";
    
    if (token != nil && [[ud objectForKey:key] isEqualToString:token] == NO) {
        [ud setObject:token forKey:key];
        [ud synchronize];
    }
    
    if (token == nil) token = [ud objectForKey:key];
    
    _token = token;

    NSLog(@"Token ready: %@", _token);
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
    NSLog(@"performFetchWithCompletionHandler");
    
    completionHandler(UIBackgroundFetchResultNoData);
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
#pragma mark - Hosts
- (NSMutableArray *)hosts {
    if (_hosts == nil) {
        _hosts = [NSMutableArray array];
        
        NSArray *hosts = [[NSUserDefaults standardUserDefaults] objectForKey:@"hosts"];
        [hosts enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            [_hosts addObject:[NSMutableDictionary dictionaryWithDictionary:obj]];
        }];
        
        if ([_hosts count] == 0) {
            [_hosts addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                   @"webId": @"web.com.tistory.macnews",
                                                                   @"title": @"Back to the Mac",
                                                                   @"url": @"http://macnews.tistory.com/m/%@",
                                                                   @"enabled": @(_token != nil)
                                                                   }]];
            [[NSUserDefaults standardUserDefaults] setObject:_hosts forKey:@"hosts"];
        }
    }
    return _hosts;
}
- (NSDictionary *)hostsMap {
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    [self.hosts enumerateObjectsUsingBlock:^(NSMutableDictionary *obj, NSUInteger idx, BOOL *stop) { map[obj[@"webId"]] = obj; }];
    return [NSDictionary dictionaryWithDictionary:map];
}
- (NSInteger)numberOfHosts {
    return [self.hosts count];
}
- (NSMutableDictionary *)hostAtIndex:(NSInteger)row {
    return self.hosts[row];
}
- (NSMutableDictionary *)hostWithWebId:(NSString *)webId {
    return self.hostsMap[webId];
}
- (void)saveHosts {
    [[NSUserDefaults standardUserDefaults] setObject:self.hosts forKey:@"hosts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setMultiHostEnabled:(BOOL)multiHostEnabled {
    [[NSUserDefaults standardUserDefaults] setBool:multiHostEnabled forKey:@"multiHostEnabled"];
}
- (BOOL)multiHostEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"multiHostEnabled"];
}

- (void)updateHostSettings {
    assert([NSThread isMainThread] == NO);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://push.smoon.kr/v1/hosts"]];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if (data == nil) return;
    
    NSArray *list = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    [list enumerateObjectsUsingBlock:^(NSMutableDictionary *obj, NSUInteger idx, BOOL *stop) { map[obj[@"webId"]] = obj; }];
    
    if (self.multiHostEnabled == NO) {
        NSDictionary *item = map[@"web.com.tistory.macnews"];
        [self.hostsMap[@"web.com.tistory.macnews"] addEntriesFromDictionary:item];
    } else {
        [list enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            if (self.hostsMap[obj[@"webId"]] == nil) {
                [self.hosts addObject:[NSMutableDictionary dictionaryWithDictionary:obj]];
            } else {
                [self.hostsMap[obj[@"webId"]] addEntriesFromDictionary:obj];
            }
        }];
    }
    [[NSUserDefaults standardUserDefaults] setObject:_hosts forKey:@"hosts"];
}
- (BOOL)setHost:(NSString *)webId enabled:(BOOL)enabled {
    if (self.token == nil) return NO;
    assert([NSThread isMainThread] == NO);
    
    NSString *pwebId = [NSString stringWithFormat:@"ios%@", [webId substringFromIndex:3]];
    
    NSMutableString *url = [NSMutableString stringWithFormat:@"https://push.smoon.kr/v1/devices/%@/registrations/%@", self.token, pwebId];
    if (enabled == NO) [url appendString:@"/delete"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[NSString stringWithFormat:@"version=%@", [[UIDevice currentDevice] systemVersion]] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSHTTPURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    if (response.statusCode == 200) {
        self.hostsMap[webId][@"enabled"] = @(enabled);
        [self saveHosts];
        return YES;
    }
    return NO;
}

@end
