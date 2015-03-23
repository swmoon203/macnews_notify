//
//  GlanceController.m
//  Macnews Notify WatchKit Extension
//
//  Created by mtjddnr on 2015. 3. 8..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "GlanceController.h"
#import <MacnewsCore/MacnewsCore.h>


@interface GlanceController()
@property (weak, nonatomic) IBOutlet WKInterfaceImage *priviewImageView;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *contentLabel;

@end


@implementation GlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    [self updateScreen];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}
- (void)updateScreen {

    NSManagedObjectContext *context = [DataStore sharedData].managedObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:1];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    
    NSError *err = nil;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&err];
    
    if ([items count] == 0) {
        [self.titleLabel setText:@"데이터가 없습니다"];
        return;
    }
    NSManagedObject *object = items[0];
    
    [self.titleLabel setText:[object valueForKey:@"title"]];
//    NSData *imageData = [object valueForKey:@"imageData"];
//    if (imageData) {
//        [self.priviewImageView setImageData:imageData];
//    }
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[(NSString *)[object valueForKey:@"contents"] dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    [self.contentLabel setText:json[@"apn"][@"message"]];
}
@end



