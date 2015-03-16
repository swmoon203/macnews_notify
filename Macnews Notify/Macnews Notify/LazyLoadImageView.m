//
//  LazyLoadImageView.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 15..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "LazyLoadImageView.h"
#import "NSString+Hashes.h"

#define LazyLoadImageViewNotification @"LazyLoadImageViewNotification"
@implementation LazyLoadImageView
static NSString *__path = nil;

static dispatch_semaphore_t __semaphore = nil; //dispatch_semaphore_create(5);
static dispatch_queue_t __workingQueue = nil;
static NSMutableSet *__workingSet = nil;

+ (NSString *)temp {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths objectAtIndex:0];
        BOOL isDir = NO;
        NSError *error;
        if (! [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
        }
        __path = cachePath;
    });
    return __path;
}

+ (void)loadImage:(NSString *)url {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __semaphore = dispatch_semaphore_create(5);
        __workingQueue = dispatch_queue_create("LazyLoadImageViewQueue", DISPATCH_QUEUE_SERIAL);
        __workingSet = [NSMutableSet set];
    });
    
    dispatch_async(__workingQueue, ^{
        if ([__workingSet containsObject:url]) return;
        [__workingSet addObject:url];
        
        dispatch_semaphore_wait(__semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *path = [[LazyLoadImageView temp] stringByAppendingPathComponent:url.sha256];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
                
                if ([data writeToFile:path atomically:NO]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:LazyLoadImageViewNotification object:url];
                    });
                }
            }
            dispatch_sync(__workingQueue, ^{
                [__workingSet removeObject:url];
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
    NSString *path = [[LazyLoadImageView temp] stringByAppendingPathComponent:url.sha256];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *data = [NSData dataWithContentsOfFile:path];
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
            });
        });
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:LazyLoadImageViewNotification object:nil];
        [LazyLoadImageView loadImage:_url];
    }
}

- (void)onNotification:(NSNotification *)noti {
    NSString *url = noti.object;
    if ([self.url isEqualToString:url] == NO) return;
    [self setUrl:url];
}

@end
