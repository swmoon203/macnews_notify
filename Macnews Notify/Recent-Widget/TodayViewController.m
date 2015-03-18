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

@interface TodayViewController () <NCWidgetProviding, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) NSString *token;

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
    
    [self updateScreen];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) return _persistentStoreCoordinator;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Macnews_Notify" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSURL *directory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.kr.smoon.ios.macnews"];
    NSURL *storeURL = [directory URLByAppendingPathComponent:@"Macnews_Notify.sqlite"];
    
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

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) return _fetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:1];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"webId == 'web.com.tistory.macnews'"]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    self.fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}

- (BOOL)updateScreen {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    NSLog(@"%lu", [sectionInfo numberOfObjects]);
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    if ([sectionInfo numberOfObjects] == 0) return completionHandler(NCUpdateResultNoData);
    [self updateScreen];
    
    completionHandler([self updateScreen] ? NCUpdateResultNewData : NCUpdateResultNoData);
}
- (IBAction)onTap:(id)sender {
    NSLog(@"onTap");
    //[self.extensionContext openURL:<#(NSURL *)#> completionHandler:<#^(BOOL success)completionHandler#>]
}

@end
