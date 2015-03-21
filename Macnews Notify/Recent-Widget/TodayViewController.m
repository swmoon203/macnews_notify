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

@interface TodayViewController () <NCWidgetProviding>

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

- (BOOL)updateScreen {
    NSManagedObjectContext *context = [DataStore sharedData].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:1];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"webId == 'web.com.tistory.macnews'"]];
    
    NSError *err = nil;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&err];
    
    if ([items count] == 0) {
        self.lblTitle.text = @"No data";
        self.lblBody.hidden = YES;
        return NO;
    }
    id item = items[0];
    
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

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    NSLog(@"widgetPerformUpdateWithCompletionHandler");
    completionHandler([self updateScreen] ? NCUpdateResultNewData : NCUpdateResultNoData);
}
- (IBAction)onTap:(id)sender {
    if (_current == nil) return;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"macnews://%@?%@", [_current valueForKey:@"webId"], [_current valueForKey:@"arg"]]];
    [self.extensionContext openURL:url completionHandler:nil];
}

@end
