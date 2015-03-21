//
//  TableViewCell.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 21..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "TableViewCell.h"
@interface TableViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *TImageView;

@end
@implementation TableViewCell
- (UIImageView *)imageView {
    return self.TImageView;
}
@end
