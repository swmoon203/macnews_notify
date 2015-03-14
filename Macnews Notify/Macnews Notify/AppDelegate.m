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

NSString *const AppNeedLoadDataNotification = @"AppNeedLoadDataNotification";
NSString *const AppNeedDataResetNotification = @"AppNeedDataResetNotification";

@interface AppDelegate ()
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;

  
    [self registerDevice];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
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

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "kr.smoon.ios.Macnews_Notify" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

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
}

#pragma mark - Notification
- (void)registerDevice {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    
    if (settings.types == UIUserNotificationTypeNone) {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
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

    [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"%@", userInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:AppNeedLoadDataNotification object:nil];
}
@end
