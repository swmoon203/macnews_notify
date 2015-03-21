//
//  DataStore.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 19..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "DataStore.h"
@interface DataStore ()

@property (strong, nonatomic) NSMutableArray *hosts;
@property (strong, readonly, nonatomic) NSDictionary *hostsMap;

@end

@implementation DataStore {
    BOOL _updating;
    dispatch_queue_t _backgroundUpdateQueue;
    NSManagedObjectContext *_backgroundObjectContext;
    
    NSInteger _lastStatusCode, _lastUpdatedCount;
}
static DataStore *__sharedData = nil;
+ (DataStore *)sharedData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedData = [[DataStore alloc] init];
    });
    return __sharedData;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"[[DataStore alloc] init]");
        _backgroundUpdateQueue = dispatch_queue_create("kr.smoon.ios.MacnewsCore.backgroundUpdateQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (NSURL *)managedObjectModelURL {
    return [[NSBundle mainBundle] URLForResource:@"Macnews_Notify" withExtension:@"momd"];
}
- (NSURL *)storeURL {
    NSURL *directory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.kr.smoon.ios.macnews"];
    return [directory URLByAppendingPathComponent:@"Macnews_Notify.sqlite"];
}

@synthesize userDefaults=_userDefaults;
- (NSUserDefaults *)userDefaults {
    if (_userDefaults) return _userDefaults;
    return (_userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.kr.smoon.ios.macnews"]);
}

- (NSInteger)responsiveMode {
    return [self.userDefaults integerForKey:@"responsiveMode"];
}
- (void)setResponsiveMode:(NSInteger)responsiveMode {
    [self.userDefaults setInteger:responsiveMode forKey:@"responsiveMode"];
}

- (NSArray *)remindOptionTitles {
    return @[ @"5분후", @"한시간후", @"내일" ];
}
- (NSInteger)remindOption {
    return [self.userDefaults integerForKey:@"remindOption"];
}
- (void)setRemindOption:(NSInteger)remindOption {
    [self.userDefaults setInteger:remindOption forKey:@"remindOption"];
}

- (NSInteger)idx {
    return [self.userDefaults integerForKey:@"idx"];
}
- (void)setIdx:(NSInteger)idx {
    [self.userDefaults setInteger:idx forKey:@"idx"];
}
- (void)resetIdx {
    [self.userDefaults removeObjectForKey:@"idx"];
}

- (NSString *)token {
    return [self.userDefaults stringForKey:@"deviceToken"];
}


- (void)resetContext {
    NSLog(@"+resetContext");
    [self deleteAllEntities:@"Notification" from:self.managedObjectContext];
    NSLog(@"-resetContext");
    
}

#pragma mark - Hosts
- (NSMutableArray *)hosts {
    if (_hosts == nil) {
        _hosts = [NSMutableArray array];
        
        NSArray *hosts = [self.userDefaults objectForKey:@"hosts"];
        [hosts enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
            [_hosts addObject:[NSMutableDictionary dictionaryWithDictionary:obj]];
        }];
        
        if ([_hosts count] == 0) {
            [_hosts addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                              @"webId": @"web.com.tistory.macnews",
                                                                              @"title": @"Back to the Mac",
                                                                              @"url": @"http://macnews.tistory.com/m/%@",
                                                                              @"enabled": @(self.token != nil)
                                                                              }]];
            [self.userDefaults setObject:_hosts forKey:@"hosts"];
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
    [self.userDefaults setObject:self.hosts forKey:@"hosts"];
    [self.userDefaults synchronize];
}

- (void)setMultiHostEnabled:(BOOL)multiHostEnabled {
    [self.userDefaults setBool:multiHostEnabled forKey:@"multiHostEnabled"];
}
- (BOOL)multiHostEnabled {
    return [self.userDefaults boolForKey:@"multiHostEnabled"];
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
    [self saveHosts];
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

#pragma mark - Data

- (void)updateData:(void (^)(NSManagedObjectContext *context, NSInteger statusCode, NSUInteger count))onComplete {
    assert([NSThread isMainThread]);
    
    if (_updating) {
        dispatch_async(_backgroundUpdateQueue, ^{
            NSLog(@"already Updating: %@", @([NSThread isMainThread]));
            onComplete(_backgroundObjectContext, _lastStatusCode, _lastUpdatedCount);
        });
    } else {
        _updating = YES;
        dispatch_async(_backgroundUpdateQueue, ^{
            NSLog(@"Update: %@", @([NSThread isMainThread]));
            if (_backgroundObjectContext == nil) {
                _backgroundObjectContext = [self newManagedObjectContext];
            }
            
            NSManagedObjectContext *context = _backgroundObjectContext;
            
            NSString *url = self.token != nil ? [NSString stringWithFormat:@"https://push.smoon.kr/v1/notification/%@/%li", self.token, (long)self.idx] :
            [NSString stringWithFormat:@"https://push.smoon.kr/v1/notification/%li", (long)self.idx];
            
            NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSURLResponse *response = nil;
            NSError *error = nil, *errorJson = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if ([(NSHTTPURLResponse *)response statusCode] != 200) {
                return onComplete(context, _lastStatusCode = [(NSHTTPURLResponse *)response statusCode], _lastUpdatedCount = 0);
            }
            
            NSString *entityName = @"Notification";
            
            NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJson];
            NSManagedObject *newManagedObject = nil;
            for (NSDictionary *obj in json) {
                NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:obj];
                item[@"reg"] = [NSDate dateWithTimeIntervalSince1970:[item[@"reg"] intValue]];
                NSDictionary *apn = [NSJSONSerialization JSONObjectWithData:[item[@"contents"] dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
                apn = apn[@"apn"];
                item[@"title"] = apn[@"title"];
                if (apn[@"image"]) item[@"image"] = apn[@"image"];
                if ([apn[@"url-args"] count] > 0) item[@"arg"] = apn[@"url-args"][0];
                newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
                [newManagedObject setValuesForKeysWithDictionary:item];
                [newManagedObject setValue:@NO forKey:@"archived"];
                
                self.idx = MAX(self.idx, [item[@"idx"] integerValue]);
                [self.userDefaults synchronize];
            }
            
            if ([newManagedObject valueForKey:@"image"] != nil) {
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[newManagedObject valueForKey:@"image"]]];
                if (imageData != nil) [newManagedObject setValue:imageData forKey:@"imageData"];
            }
            
            NSError *dbError = nil;
            [context save:&dbError];
            
            _updating = NO;
            onComplete(context, _lastStatusCode = [(NSHTTPURLResponse *)response statusCode], _lastUpdatedCount = [json count]);
        });
    }
}

- (void)downloadPreviewImages {
    assert([NSThread isMainThread] == NO);
    
    NSManagedObjectContext *context = [self newManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:5];
    [fetchRequest setFetchLimit:5];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"image != nil && imageData == nil"]];
    [fetchRequest setPropertiesToFetch:@[ @"image" ]];
    
    NSError *err = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&err];
    
    for (NSManagedObject *object in results) {
        NSLog(@"Download: %@", [object valueForKey:@"image"]);
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[object valueForKey:@"image"]]];
        if (data) {
            [object setValue:data forKey:@"imageData"];
        }
    }
    [context save:&err];
}
@end
