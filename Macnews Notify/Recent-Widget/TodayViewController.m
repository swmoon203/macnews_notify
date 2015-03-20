//
//  TodayViewController.m
//  Recent-Widget
//
//  Created by mtjddnr on 2015. 3. 17..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <CoreData/CoreData.h>
#import <MacnewsCore/MacnewsCore.h>

@interface TodayViewController () <NCWidgetProviding, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblBody;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TodayViewController {
    NSInteger _idx;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSLog(@"viewDidLoad");
    
    [self updateData];
    [self updateScreen];
}


- (NSManagedObjectContext *)managedObjectContext {
    return [DataStore sharedData].managedObjectContext;
}

@synthesize fetchedResultsController=_fetchedResultsController;
- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) return _fetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:1];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"webId == 'web.com.tistory.macnews'"]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self managedObjectContext] sectionNameKeyPath:nil cacheName:@"Master"];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}
- (BOOL)updateData {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.kr.smoon.ios.macnews"];
    NSInteger idx = [userDefaults integerForKey:@"idx"];
    NSString *token = [userDefaults stringForKey:@"deviceToken"];
    
    NSLog(@"Start Loading %li", (long)idx);
    
    NSString *url = token != nil ? [NSString stringWithFormat:@"https://push.smoon.kr/v1/notification/%@/%li", token, (long)idx] :
    [NSString stringWithFormat:@"https://push.smoon.kr/v1/notification/%li", (long)idx];
        
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLResponse *response = nil;
    NSError *error = nil, *errorJson = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
    if ([(NSHTTPURLResponse *)response statusCode] != 200) {
        NSLog(@"Error Loading");
        return NO;
    }
        
    NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJson];
    NSMutableArray *list = [NSMutableArray array];
    for (NSDictionary *obj in json) {
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:obj];
        item[@"reg"] = [NSDate dateWithTimeIntervalSince1970:[item[@"reg"] intValue]];
        NSDictionary *apn = [NSJSONSerialization JSONObjectWithData:[item[@"contents"] dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
        apn = apn[@"apn"];
        item[@"title"] = apn[@"title"];
        if (apn[@"image"]) item[@"image"] = apn[@"image"];
        if ([apn[@"url-args"] count] > 0) item[@"arg"] = apn[@"url-args"][0];
        [list addObject:item];
        idx = MAX(idx, [item[@"idx"] integerValue]);
        NSLog(@"+idx:%lu", idx);
    }
        
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
        
    NSLog(@"Downloaded: %lu", (unsigned long)[list count]);
    for (NSDictionary *item in list) {
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        [newManagedObject setValuesForKeysWithDictionary:item];
        [newManagedObject setValue:@NO forKey:@"archived"];
        
        if ([newManagedObject valueForKey:@"image"] != nil && idx == [item[@"idx"] integerValue]) {
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[newManagedObject valueForKey:@"image"]]];
            if (imageData != nil) {
                [newManagedObject setValue:imageData forKey:@"imageData"];
            }
        }
    }
    
    NSError *dbError = nil;
    if (![context save:&dbError]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", dbError, [dbError userInfo]);
        abort();
    }
    
    [userDefaults setInteger:idx forKey:@"idx"];
    [userDefaults synchronize];
    
    NSLog(@"End Loading %li", (long)idx);
    
    return [list count] != 0;
}
- (BOOL)updateScreen {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    NSLog(@"[sectionInfo numberOfObjects] == %lu", (unsigned long)[sectionInfo numberOfObjects]);
    if ([sectionInfo numberOfObjects] == 0) {
        self.lblTitle.text = @"No data";
        self.lblBody.hidden = YES;
        return NO;
    }
    self.lblBody.hidden = NO;
    id item = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    if (_idx == [[item valueForKey:@"idx"] integerValue]) return NO;
        
    
    self.lblTitle.text = [item valueForKey:@"title"];
    
    NSString *contentsString = [item valueForKey:@"contents"];
    NSDictionary *contents = [NSJSONSerialization JSONObjectWithData:[contentsString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    self.lblBody.text = contents[@"apn"][@"message"];
    if ([item valueForKey:@"imageData"] != nil) {
        self.imageView.image = [UIImage imageWithData:[item valueForKey:@"imageData"]];
    }
    _idx = [[item valueForKey:@"idx"] integerValue];
    return YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self updateScreen];
}


- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    NSLog(@"widgetPerformUpdateWithCompletionHandler");
    completionHandler([self updateData] ? NCUpdateResultNewData : NCUpdateResultNoData);
}
- (IBAction)onTap:(id)sender {
    if ([[self.fetchedResultsController sections][0] numberOfObjects] == 0) return;
    
    id item = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"macnews://%@?%@", [item valueForKey:@"webId"], [item valueForKey:@"arg"]]];
    [self.extensionContext openURL:url completionHandler:nil];
}

@end
