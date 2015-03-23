//
//  TableController.m
//  Macnews Notify WatchKit Extension
//
//  Created by mtjddnr on 2015. 3. 8..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "TableController.h"
#import "RowController.h"
#import <MacnewsCore/MacnewsCore.h>

@interface TableController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;

@property (nonatomic) BOOL archived;
@end


@implementation TableController {

}

- (BOOL)archived {
    return [[DataStore sharedData].userDefaults boolForKey:@"watchKit.view.archived"];
}
- (void)setArchived:(BOOL)archived {
    [[DataStore sharedData].userDefaults setBool:archived forKey:@"watchKit.view.archived"];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
    [self loadData];
    [self updateMenu];
}

- (void)loadData {
    NSLog(@"loadData");
    NSManagedObjectContext *context = [DataStore sharedData].managedObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setFetchLimit:20];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"archived == %@", @(self.archived)]];
    
    NSError *err = nil;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&err];
    
    
    [self.table setNumberOfRows:[items count] withRowType:@"row"];
    [items enumerateObjectsUsingBlock:^(NSManagedObject *obj, NSUInteger idx, BOOL *stop) {
        RowController *row = [self.table rowControllerAtIndex:idx];
        row.object = obj;
        [row.titleLabel setText:[obj valueForKey:@"title"]];
    }];
    
}
- (void)updateMenu {
    [self clearAllMenuItems];
    [self addMenuItemWithImageNamed:self.archived ? @"listIcon" : @"archiveIcon" title:self.archived ? @"목록 열기" : @"보관 열기" action:@selector(onTapSwitch)];
    [self addMenuItemWithImageNamed:@"settingIcon" title:@"설정" action:@selector(onTabSetting)];
}

- (void)willActivate {
    NSLog(@"willActivate");
    [self loadData];
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    NSLog(@"didDeactivate");
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    NSLog(@"%i", (int)rowIndex);
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    NSLog(@"%@", segueIdentifier);
    return [(RowController *)[table rowControllerAtIndex:rowIndex] object];
}

- (void)onTabSetting {
    
}

- (void)onTapSwitch {
    self.archived = !self.archived;
    [self loadData];
    [self updateMenu];
}


@end



