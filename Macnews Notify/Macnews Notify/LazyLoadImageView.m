//
//  LazyLoadImageView.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 15..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "LazyLoadImageView.h"

NSString *const LazyLoadImageViewNotification = @"LazyLoadImageViewNotification";

@implementation LazyLoadImageView

static dispatch_semaphore_t __semaphore = nil; //dispatch_semaphore_create(5);
static dispatch_queue_t __workingQueue = nil;

+ (void)loadImage:(NSString *)url {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __semaphore = dispatch_semaphore_create(5);
        __workingQueue = dispatch_queue_create("LazyLoadImageViewQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_async(__workingQueue, ^{
        dispatch_semaphore_wait(__semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSLog(@"Download: %@", url);
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (data != nil) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:LazyLoadImageViewNotification
                                                                        object:nil
                                                                        userInfo:@{ @"url": url, @"imageData": data }];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:LazyLoadImageViewNotification
                                                                        object:nil
                                                                      userInfo:@{ @"url": url }];
                }
            });
            dispatch_semaphore_signal(__semaphore);
        });
    });
}


- (void)setUrl:(NSString *)url {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _url = [url copy];
    self.image = nil;
    if (url == nil) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:LazyLoadImageViewNotification object:nil];
    [LazyLoadImageView loadImage:_url];
}

- (void)onNotification:(NSNotification *)noti {
    NSString *url = noti.userInfo[@"url"];
    if ([self.url isEqualToString:url] == NO || noti.userInfo[@"imageData"] == nil) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage *image = [UIImage imageWithData:noti.userInfo[@"imageData"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = image;
        });
    });
}

@end
