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
    if (context == nil) context = [self loadPages];
    [super awakeWithContext:context];
    
    _context = context;
    [self updateScreen];
    [self updateMenu];
}

- (void)willActivate {
    [super willActivate];
    [self updateScreen];
    [self updateMenu];
}

- (void)didDeactivate {
    [super didDeactivate];
}

- (NSManagedObject *)loadPages {
    NSManagedObjectContext *context = [DataStore sharedData].managedObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    [fetchRequest setFetchBatchSize:5];
    [fetchRequest setFetchLimit:5];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"archived = %@", @(NO)]];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"idx" ascending:NO] ]];
    
    NSError *err = nil;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&err];
    
    if ([items count] == 0) {
        return nil;
    }
    
    if ([items count] > 1) {
        NSMutableArray *page = [NSMutableArray arrayWithCapacity:[items count]];
        for (int i = 0; i < [items count]; i++) [page addObject:@"page"];
        [WKInterfaceController reloadRootControllersWithNames:page contexts:items];
        return nil;
    }
    return items[0];
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

- (void)updateMenu {
    [self clearAllMenuItems];
    BOOL archived = [[_context valueForKey:@"archived"] boolValue];
    [self addMenuItemWithImageNamed:archived ? @"listIcon" : @"archiveIcon" title:archived ? @"복원" : @"보관" action:@selector(switchArchive)];
    [self addMenuItemWithItemIcon:WKMenuItemIconAdd title:@"읽기 목록" action:@selector(addToReadingList)];
    [self addMenuItemWithItemIcon:WKMenuItemIconTrash title:@"삭제" action:@selector(deleteArticle)];
}


- (void)switchArchive {
    [_context setValue:@(![[_context valueForKey:@"archived"] boolValue]) forKey:@"archived"];
    [self loadPages];
}

- (void)addToReadingList{
    [[DataStore sharedData] addToSafariReadingList:_context];
}
- (void)deleteArticle {
    NSManagedObjectContext *context = [DataStore sharedData].managedObjectContext;
    [context deleteObject:_context];
    NSError *err = nil;
    [context save:&err];
    [self loadPages];
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

