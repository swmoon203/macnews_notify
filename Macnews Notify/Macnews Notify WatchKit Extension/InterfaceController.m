//
//  InterfaceController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 23..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier {
    return segueIdentifier;
}
@end



