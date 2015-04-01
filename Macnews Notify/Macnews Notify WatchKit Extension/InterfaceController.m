//
//  InterfaceController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 23..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "InterfaceController.h"

@interface UIImage (alpha)
- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha;
- (UIImage *)imageByScaledSize:(CGSize)newSize;
@end

@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *group;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *contentLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *noDataGroup;

@end


@implementation InterfaceController {
    NSManagedObject *_context;
}
- (void)setContext:(NSManagedObject *)context {
    _context = context;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    _context = context;
    [self updateScreen];
}

- (void)willActivate {
    [super willActivate];
    [self updateScreen];
}

- (void)didDeactivate {
    [super didDeactivate];
}
- (void)updateScreen {
    if (_context == nil) {
        [self.contentLabel setHidden:YES];
        [self.group setBackgroundImageData:nil];
        [self.noDataGroup setHidden:NO];
        return;
    }
    [self.contentLabel setHidden:NO];
    [self.noDataGroup setHidden:YES];
    
    NSData *imageData = [_context valueForKey:@"imageData"];
    [self.contentLabel setText:[_context valueForKey:@"title"]];
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        image = [image imageByScaledSize:self.contentFrame.size];
        image = [image imageByApplyingAlpha:0.7];
        imageData = UIImagePNGRepresentation(image);
        [self.group setBackgroundImageData:imageData];
    } else {
        [self.group setBackgroundImageNamed:@"bgtopohigh"];
    }
}
@end

@implementation UIImage (alpha)
- (UIImage *)imageByApplyingAlpha:(CGFloat)alpha {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, self.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}
- (UIImage *)imageByScaledSize:(CGSize)newSize {
    if (self.size.width < newSize.width && self.size.height < newSize.height) {
        return self;
    }
    
    CGFloat widthScale = newSize.width / self.size.width;
    CGFloat heightScale = newSize.height / self.size.height;
    
    CGFloat scaleFactor;
    
    widthScale > heightScale ? (scaleFactor = widthScale) : (scaleFactor = heightScale);
    CGSize scaledSize = CGSizeMake(self.size.width * scaleFactor, self.size.height * scaleFactor);
    
    CGPoint imageDrawOrigin = CGPointMake(0, 0);
    widthScale > heightScale ?  (imageDrawOrigin.y = (newSize.height - scaledSize.height) * 0.5) :
    (imageDrawOrigin.x = (newSize.width - scaledSize.width) * 0.5);
    
    CGRect imageDrawRect = CGRectMake(imageDrawOrigin.x, imageDrawOrigin.y, scaledSize.width, scaledSize.height);
    return [UIImage imageWithImage:self scaledToSize:newSize inRect:imageDrawRect];
}
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize inRect:(CGRect)rect {
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 2.0);
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end

