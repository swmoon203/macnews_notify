//
//  UIMutableUserNotificationAction+Simple.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 21..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "UIMutableUserNotificationAction+Simple.h"


@implementation UIMutableUserNotificationAction (Simple)
+ (UIMutableUserNotificationAction *)userNotificationActionWith:(NSDictionary *)options {
    UIMutableUserNotificationAction *action = [[UIMutableUserNotificationAction alloc] init];
    [options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [action setValue:obj forKey:key];
    }];
    return action;
}
+ (NSArray *)userNotificationActionsWith:(NSArray *)options {
    NSMutableArray *actions = [NSMutableArray array];
    [options enumerateObjectsUsingBlock:^(NSDictionary *option, NSUInteger idx, BOOL *stop) {
        [actions addObject:[self userNotificationActionWith:option]];
    }];
    return actions;
}
@end

