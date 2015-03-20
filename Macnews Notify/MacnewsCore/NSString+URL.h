//
//  NSString+URL.h
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 8..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URL)
+ (NSString *)stringWithURLResponse:(NSURLResponse *)response data:(NSData *)data;

- (NSString *)stringByURLEncoded;
- (NSString *)stringByURLDecoded;
- (NSString *)stringByURLEncodedWith:(NSStringEncoding)encoding;
- (NSString *)stringByURLDecodedWith:(NSStringEncoding)encoding;

- (NSString *)stringByRemovingControlCharacters;
@end

extern NSStringEncoding const NSCP949StringEncoding;
extern NSStringEncoding const NSEUCKRStringEncoding;