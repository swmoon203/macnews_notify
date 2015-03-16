//
//  AppDelegate.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 6..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

#pragma mark Remote Push
@property (readonly, strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSDictionary *receivedNotification;

- (NSString *)tempDirectory;

#pragma mark Core Data
- (NSURL *)applicationDocumentsDirectory;


@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)saveContext;
- (void)resetContext;

@property (nonatomic) NSInteger idx;
- (void)resetIdx;

#pragma mark Hosts
- (NSInteger)numberOfHosts;
- (NSMutableDictionary *)hostAtIndex:(NSInteger)row; //{ title, webId, enabled, sites }
- (NSMutableDictionary *)hostWithWebId:(NSString *)webId;

@property (nonatomic) BOOL multiHostEnabled;

//multithread needed
- (void)updateHostSettings;
- (BOOL)setHost:(NSString *)webId enabled:(BOOL)enabled;

#pragma mark Categories


@end

NSString *const AppNeedLoadDataNotification;
NSString *const AppNeedDataResetNotification;
NSString *const AppNeedReloadHostSettingsNotification;