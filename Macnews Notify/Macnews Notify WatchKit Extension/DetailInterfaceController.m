//
//  DetailInterfaceController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 23..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "DetailInterfaceController.h"
#import <CoreData/CoreData.h>
#import <MacnewsCore/MacnewsCore.h>


@interface DetailInterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceImage *imageView;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *contentLabel;
@end


@implementation DetailInterfaceController {
    NSManagedObject *_object;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
    _object = context;
    [self updataScreen];
    [self updateMenu];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [self updataScreen];
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)updataScreen {
    if (_object == nil) return;
    
    [self.titleLabel setText:[_object valueForKey:@"title"]];
    
    if ([_object valueForKey:@"imageData"] == nil) {
        [self.imageView setHidden:YES];
    } else {
        NSData *data = [_object valueForKey:@"imageData"];
        NSLog(@"%lu", (unsigned long)[data length]);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self.imageView setImageData:data];
        });
    }
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[(NSString *)[_object valueForKey:@"contents"] dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    [self.contentLabel setText:json[@"apn"][@"message"]];
}
- (IBAction)onTapOpen {
    [WKInterfaceController openParentApplication:@{ @"webId": [_object valueForKey:@"webId"], @"arg": [_object valueForKey:@"arg"] }
                                           reply:^(NSDictionary *replyInfo, NSError *error) {
                                               NSLog(@"%@", replyInfo);
                                               NSLog(@"%@", error);
                                           }];
}

- (void)updateMenu {
    [self clearAllMenuItems];
    BOOL archived = [[_object valueForKey:@"archived"] boolValue];
    [self addMenuItemWithImageNamed:archived ? @"listIcon" : @"archiveIcon" title:archived ? @"복원" : @"보관" action:@selector(switchArchive)];
    [self addMenuItemWithItemIcon:WKMenuItemIconTrash title:@"삭제" action:@selector(deleteArticle)];
    [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"읽기 목록" action:@selector(addToReadingList)];
}

- (void)switchArchive {
    [_object setValue:@(![[_object valueForKey:@"archived"] boolValue]) forKey:@"archived"];
    [self updateMenu];
}

- (void)addToReadingList{
    [[DataStore sharedData] addToSafariReadingList:_object];
}
- (void)deleteArticle {
    NSManagedObjectContext *context = [DataStore sharedData].managedObjectContext;
    [context deleteObject:_object];
    NSError *err = nil;
    [context save:&err];
    [self popController];
}
@end



