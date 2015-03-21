//
//  DataStore.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 19..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataStore.h"

@interface DataStore : CoreDataStore
+ (DataStore *)sharedData;

@property (strong, nonatomic, readonly) NSUserDefaults *userDefaults;

@property (strong, nonatomic, readonly) NSString *token;
@property (nonatomic) NSInteger responsiveMode;

- (NSArray *)remindOptionTitles;
@property (nonatomic) NSInteger remindOption;
@property (nonatomic, readonly) NSTimeInterval remindOptionTimeInterval;

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

- (void)resetContext;

- (void)updateData:(void (^)(NSManagedObjectContext *context, NSInteger statusCode, NSUInteger count))onComplete;

- (void)downloadPreviewImages;
@end
