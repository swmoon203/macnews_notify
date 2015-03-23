//
//  RowController.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 22..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <CoreData/CoreData.h>

@interface RowController : NSObject
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;

@property (strong, nonatomic) NSManagedObject *object;
@end
