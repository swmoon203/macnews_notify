//
//  UIMutableUserNotificationAction+Simple.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 21..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIMutableUserNotificationAction (Simple)
+ (UIMutableUserNotificationAction *)userNotificationActionWith:(NSDictionary *)options;
+ (NSArray *)userNotificationActionsWith:(NSArray *)options;
@end
