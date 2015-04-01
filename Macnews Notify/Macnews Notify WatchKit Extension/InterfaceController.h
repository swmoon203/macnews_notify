//
//  InterfaceController.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 23..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <MacnewsCore/MacnewsCore.h>

@interface InterfaceController : WKInterfaceController
- (void)setContext:(NSManagedObject *)context;
@end
