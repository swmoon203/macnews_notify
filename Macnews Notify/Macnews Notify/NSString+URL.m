//
//  NSString+URL.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 8..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "NSString+URL.h"

NSStringEncoding const NSCP949StringEncoding = 0x80000422;
NSStringEncoding const NSEUCKRStringEncoding = 0x80000940;

@implementation NSString (URL)
+ (NSString *)stringWithURLResponse:(NSURLResponse *)response data:(NSData *)data {
    if (response == nil || data == nil) return nil;
    NSString *returnValue;
    NSString *encoding = [(NSHTTPURLResponse *)response textEncodingName];
    if (encoding) {
        CFStringEncoding cfse = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)encoding);
        NSStringEncoding se = CFStringConvertEncodingToNSStringEncoding(cfse);
        returnValue = [[NSString alloc] initWithData:data encoding:se];
    }
    
    //인코딩 실패시 그냥 가능성 있는거 다 해본다
    if (returnValue == nil) {
        //UTF-8
        returnValue = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if (returnValue == nil) {
        //EUC-KR
        returnValue = [[NSString alloc] initWithData:data encoding:NSEUCKRStringEncoding];
    }
    if (returnValue == nil) {
        //CP949
        returnValue = [[NSString alloc] initWithData:data encoding:NSCP949StringEncoding];
    }
    
    return returnValue;
}

- (NSString *)stringByURLEncoded {
    CFStringRef encoded = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (__bridge CFStringRef)self,
                                                                  NULL,
                                                                  (__bridge CFStringRef)@";/?:@&=+$,",
                                                                  kCFStringEncodingUTF8);
    if (encoded == NULL) return nil;
    //NSString *ret = [NSString stringWithString:(__bridge_transfer NSString *)encoded];
    //CFRelease(encoded);
    return (__bridge_transfer NSString *)encoded; //ret;
}

- (NSString *)stringByURLDecoded {
    CFStringRef decoded = CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,
                                                                     (__bridge CFStringRef)self,
                                                                     CFSTR(""));
    if (decoded == NULL) return nil;
    //NSString *ret = [NSString stringWithString:(__bridge_transfer NSString *)decoded];
    //CFRelease(decoded);
    return (__bridge_transfer NSString *)decoded;//ret;
}

- (NSString *)stringByURLEncodedWith:(NSStringEncoding)encoding {
    CFStringEncoding cencoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    
    CFStringRef encoded = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (__bridge CFStringRef)self,
                                                                  NULL,
                                                                  (__bridge CFStringRef)@";/?:@&=+$,",
                                                                  cencoding);
    if (encoded == NULL) return nil;
    //NSString *ret = [NSString stringWithString:(__bridge NSString *)encoded];
    //CFRelease(encoded);
    return (__bridge_transfer NSString *)encoded;
}

- (NSString *)stringByURLDecodedWith:(NSStringEncoding)encoding {
    CFStringEncoding cencoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    CFStringRef decoded = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                  (__bridge CFStringRef)self,
                                                                                  CFSTR(""),
                                                                                  cencoding);
    if (decoded == NULL) return nil;
    //NSString *ret = [NSString stringWithString:(__bridge_transfer NSString *)decoded];
    //CFRelease(decoded);
    return (__bridge_transfer NSString *)decoded;
}

- (NSString *)stringByRemovingControlCharacters {
    NSCharacterSet *controlChars = [NSCharacterSet controlCharacterSet];
    NSRange range = [self rangeOfCharacterFromSet:controlChars];
    if (range.location != NSNotFound) { 
        NSMutableString *mutable = [NSMutableString stringWithString:self]; 
        while (range.location != NSNotFound) { 
#if DEBUG
            NSString *str = [mutable substringWithRange:range];
            if ([str length] == 1) {
                str = [NSString stringWithFormat:@"%@ %i", str, [str characterAtIndex:0]];
            }
            NSLog(@"Found: (%i, %i) %@", range.location, range.length, str);
#endif
            [mutable deleteCharactersInRange:range]; 
            range = [mutable rangeOfCharacterFromSet:controlChars]; 
        } 
        return mutable; 
    } 
    return self; 
} 

@end
