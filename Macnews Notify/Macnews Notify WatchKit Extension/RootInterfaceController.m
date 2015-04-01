//
//  RootInterfaceController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 4. 1..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "RootInterfaceController.h"
#import <MacnewsCore/MacnewsCore.h>


@interface RootInterfaceController()

@end


@implementation RootInterfaceController

- (void)awakeWithContext:(id)context {
    if (context == nil) context = [self loadPages];
    [super awakeWithContext:context];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (NSManagedObject *)loadPages {
    NSManagedObjectContext *context = [DataStore sharedData].managedObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:5];
    [fetchRequest setFetchLimit:5];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    
    NSError *err = nil;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&err];
    
    if ([items count] == 0) {
        return nil;
    }
    
    if ([items count] > 1) {
        NSMutableArray *page = [NSMutableArray arrayWithCapacity:[items count]];
        for (int i = 0; i < [items count]; i++) [page addObject:@"page"];
        [WKInterfaceController reloadRootControllersWithNames:page contexts:items];
        return nil;
    }
    return items[0];
}
@end



