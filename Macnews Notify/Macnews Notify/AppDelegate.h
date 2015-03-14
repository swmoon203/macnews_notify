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

#pragma mark Core Data
- (NSURL *)applicationDocumentsDirectory;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)saveContext;
- (void)resetContext;

@end

NSString *const AppNeedLoadDataNotification;
NSString *const AppNeedDataResetNotification;