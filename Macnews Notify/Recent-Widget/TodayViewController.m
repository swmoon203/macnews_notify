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
    id _current;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
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

- (BOOL)updateScreen {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    NSLog(@"[sectionInfo numberOfObjects] == %lu", (unsigned long)[sectionInfo numberOfObjects]);
    if ([sectionInfo numberOfObjects] == 0) {
        self.lblTitle.text = @"No data";
        self.lblBody.hidden = YES;
        return NO;
    }
    id item = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    if ([[_current valueForKey:@"idx"] integerValue] == [[item valueForKey:@"idx"] integerValue] && [item valueForKey:@"imageData"] == nil) return NO;
    
    self.lblBody.hidden = NO;
    
    self.lblTitle.text = [item valueForKey:@"title"];
    
    NSString *contentsString = [item valueForKey:@"contents"];
    NSDictionary *contents = [NSJSONSerialization JSONObjectWithData:[contentsString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    self.lblBody.text = contents[@"apn"][@"message"];
    if ([item valueForKey:@"imageData"] != nil) {
        self.imageView.image = [UIImage imageWithData:[item valueForKey:@"imageData"]];
    }
    _current = item;
    return YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self updateScreen];
}


- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    NSLog(@"widgetPerformUpdateWithCompletionHandler");
    completionHandler([self updateScreen] ? NCUpdateResultNewData : NCUpdateResultNoData);
}
- (IBAction)onTap:(id)sender {
    if ([[self.fetchedResultsController sections][0] numberOfObjects] == 0) return;
    
    id item = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"macnews://%@?%@", [item valueForKey:@"webId"], [item valueForKey:@"arg"]]];
    [self.extensionContext openURL:url completionHandler:nil];
}

@end
