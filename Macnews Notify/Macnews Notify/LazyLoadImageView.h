//
//  LazyLoadImageView.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 15..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LazyLoadImageView : UIImageView
@property (strong, nonatomic) NSString *url;
@end

NSString *const LazyLoadImageViewNotification;