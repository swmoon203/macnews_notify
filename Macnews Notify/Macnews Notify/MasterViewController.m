//
//  MasterViewController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 6..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import "LazyLoadImageView.h"

@implementation MasterViewController {
    BOOL _loading;
    UIRefreshControl *_refreshControl;
    NSDictionary *_hostTitles;
}

- (AppDelegate *)app {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataFromServer) name:AppNeedLoadDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataFromServer) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:AppNeedDataResetNotification object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      self.fetchedResultsController = nil;
                                                      [self.tableView reloadData];
                                                  }];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(loadDataFromServer) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];
}

- (void)viewDidAppear:(BOOL)animated {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (app.receivedNotification != nil) {
    //    [self performSegueWithIdentifier:@"showDetail" sender:self];
    }
}

#pragma mark - Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@[ @"showDetail", @"showDetail2" ] containsObject:segue.identifier]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
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
        if (_hostTitles == nil) {
            NSMutableDictionary *h = [NSMutableDictionary dictionary];
            NSArray *hosts = (NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:@"hosts"];
            [hosts enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                h[obj[@"webId"]] = obj[@"title"];
            }];
            _hostTitles = h;
        }
 
        if (_hostTitles[[object valueForKey:@"webId"]] != nil) {
            NSString *name = _hostTitles[[object valueForKey:@"webId"]];
            title = [NSString stringWithFormat:@"[%@] %@", name, title];
        }
    }
    cell.textLabel.text = title;
    //cell.previewImage.hidden = YES;
    if ([object valueForKey:@"image"] != nil) {
        //cell.previewImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[object valueForKey:@"image"]]]];
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
                                         NSLog(@"Action to perform with Button2!");
                                     }];
    //button2.backgroundColor = [UIColor greenColor]; //arbitrary color
    
    return @[ delete, archive ]; //array with all the buttons you want. 1,2,3, etc...
}

#pragma mark - Data
- (void)loadDataFromServer {
    if (_loading) return;
    _loading = YES;
    [_refreshControl beginRefreshing];
    NSLog(@"Start Loading");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *url = self.app.token != nil ? [NSString stringWithFormat:@"https://push.smoon.kr/v1/notification/%@/%li", self.app.token, (long)self.app.idx] :
        [NSString stringWithFormat:@"https://push.smoon.kr/v1/notification/%li", (long)self.app.idx];
        
        NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLResponse *response = nil;
        NSError *error = nil, *errorJson = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if ([(NSHTTPURLResponse *)response statusCode] != 200) {
            _loading = NO;
            // TODO: ui error: network
            NSLog(@"Error Loading");
            dispatch_async(dispatch_get_main_queue(), ^{
                [_refreshControl endRefreshing];
            });
            return;
        }
        
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&errorJson];
        NSMutableArray *list = [NSMutableArray array];
        [json enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:obj];
            item[@"reg"] = [NSDate dateWithTimeIntervalSince1970:[item[@"reg"] intValue]];
            NSDictionary *apn = [NSJSONSerialization JSONObjectWithData:[item[@"contents"] dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            apn = apn[@"apn"];
            item[@"title"] = apn[@"title"];
            if (apn[@"image"]) item[@"image"] = apn[@"image"];
            if ([apn[@"url-args"] count] > 0) item[@"arg"] = apn[@"url-args"][0];
            [list addObject:item];
            self.app.idx = MAX(self.app.idx, [item[@"idx"] integerValue]);
        }];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
            NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
            
            
            [list enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
                NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
                [newManagedObject setValuesForKeysWithDictionary:item];
            }];
            
            NSError *dbError = nil;
            if (![context save:&dbError]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            _loading = NO;
            [_refreshControl endRefreshing];
            NSLog(@"End Loading");
        });
    });
}

#pragma mark - Fetched results controller
- (NSManagedObjectContext *)managedObjectContext {
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) return _fetchedResultsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notification" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"idx" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
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

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

@end
