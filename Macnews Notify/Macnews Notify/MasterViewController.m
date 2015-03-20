//
//  MasterViewController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 6..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import <MacnewsCore/MacnewsCore.h>
#import "AppDelegate.h"

@implementation MasterViewController {
    BOOL _loading;
    UIRefreshControl *_refreshControl;
    BOOL _archived;
    NSMutableDictionary *_imageMap;
    
    NSOperationQueue *_imageDownloadQueue;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    _imageMap = [NSMutableDictionary dictionary];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataFromServer) name:AppNeedLoadDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataFromServer) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(loadDataFromServer) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];
}

- (void)viewDidAppear:(BOOL)animated {
//    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    if (app.receivedNotification != nil) {
//    //    [self performSegueWithIdentifier:@"showDetail" sender:self];
//    }
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@[ @"showDetail", @"showDetail2", @"notification" ] containsObject:segue.identifier] == NO) return;
    
    DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
    
    if ([@[ @"showDetail", @"showDetail2" ] containsObject:segue.identifier]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [controller setDetailItem:object];
        
    } else if ([@[ @"notification" ] containsObject:segue.identifier]) {
        [controller setDetailItem:nil];
        NSDictionary *item = sender;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:[[DataStore sharedData] hostWithWebId:item[@"webId"]][@"url"], item[@"arg"]]];
        
        [controller setUrl:url];
    }
    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    controller.navigationItem.leftItemsSupplementBackButton = YES;
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:([object valueForKey:@"image"] != nil ? @"Cell" : @"CellNoImage") forIndexPath:indexPath];
    
    NSString *title = [object valueForKey:@"title"];;
    if ([[object valueForKey:@"webId"] isEqualToString:@"web.com.tistory.macnews"] == NO) {
        
        NSString *name = [[DataStore sharedData] hostWithWebId:[object valueForKey:@"webId"]][@"title"];
        if (name != nil) {
            title = [NSString stringWithFormat:@"[%@] %@", name, title];
        }
    }
    cell.textLabel.text = title;
    cell.imageView.image = nil;
    if ([object valueForKey:@"image"] != nil) {
        if ([object valueForKey:@"imageData"] != nil) {
            NSData *data = [object valueForKey:@"imageData"];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                UIImage *image = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.imageView.image = image;
                });
            });
        } else if (_imageMap[[object valueForKey:@"image"]] == nil) {
            NSString *url = [object valueForKey:@"image"];
            NSManagedObjectID *objectId = [object objectID];
            _imageMap[url] = objectId;
            [[self imageDownloadQueue] addOperationWithBlock:^{
                NSLog(@"Download: %@", url);
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
                
                if (data) {
                    NSManagedObjectContext *context = [[DataStore sharedData] newManagedObjectContext];
                    NSManagedObject *objectData = [context objectWithID:objectId];
                    [objectData setValue:data forKey:@"imageData"];
                    NSError *error = nil;
                    [context save:&error];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_imageMap removeObjectForKey:url];
                });
            }];
        }
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                      title:@"삭제"
                                                                    handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
                                                                        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
                                                                        
                                                                        NSError *error = nil;
                                                                        if (![context save:&error]) {
                                                                            // Replace this implementation with code to handle the error appropriately.
                                                                            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                                                            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                                                            abort();
                                                                        }
                                    }];
    //button.backgroundColor = [UIColor redColor]; //arbitrary color
    UITableViewRowAction *archive = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                       title:@"저장"
                                                                     handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                         NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
                                                                         id item = [self.fetchedResultsController objectAtIndexPath:indexPath];
                                                                         [item setValue:@YES forKey:@"archived"];
                                                                         NSError *error = nil;
                                                                         if (![context save:&error]) {
                                                                             // Replace this implementation with code to handle the error appropriately.
                                                                             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                                                             NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                                                             abort();
                                                                         }
                                                                         
                                     }];
    //button2.backgroundColor = [UIColor greenColor]; //arbitrary color
    
    return _archived ? @[ delete] : @[ delete, archive ]; //array with all the buttons you want. 1,2,3, etc...
}

#pragma mark - Data
- (void)loadDataFromServer {
    assert([NSThread isMainThread]);
    if (_loading) return;
    _loading = YES;
    [_refreshControl beginRefreshing];
    NSLog(@"Start Loading %li", (long)[DataStore sharedData].idx);
    
    UIBackgroundTaskIdentifier taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[DataStore sharedData] updateData:^(NSInteger statusCode, NSUInteger count) {
            _loading = NO;
            NSLog(@"End Loading %li", (long)[DataStore sharedData].idx);
            dispatch_async(dispatch_get_main_queue(), ^{
                [_refreshControl endRefreshing];
                [[UIApplication sharedApplication] endBackgroundTask:taskId];
            });
        }];
    });
}

#pragma mark - Fetched results controller
- (NSManagedObjectContext *)managedObjectContext {
    return [DataStore sharedData].managedObjectContext;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) return _fetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"archived == %@", @(_archived)]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    self.fetchedResultsController.delegate = self;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (IBAction)onSegmentedChange:(UISegmentedControl *)sender {
    _archived = sender.selectedSegmentIndex == 1;
    
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    [self.fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"archived == %@", @(_archived)]];
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [self.tableView reloadData];
}

#pragma mark - Image Downloader
- (NSOperationQueue *)imageDownloadQueue {
    if (_imageDownloadQueue) return _imageDownloadQueue;
    _imageDownloadQueue = [[NSOperationQueue alloc] init];
    _imageDownloadQueue.maxConcurrentOperationCount = 3;
    _imageDownloadQueue.qualityOfService = NSQualityOfServiceBackground;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      UIBackgroundTaskIdentifier taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                                                          [_imageDownloadQueue cancelAllOperations];
                                                      }];
                                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                                          [_imageDownloadQueue waitUntilAllOperationsAreFinished];
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              [[UIApplication sharedApplication] endBackgroundTask:taskId];
                                                          });
                                                      });
                                                  }];
    return _imageDownloadQueue;
}

@end
