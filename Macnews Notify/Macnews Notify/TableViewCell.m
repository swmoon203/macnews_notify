//
//  TableViewCell.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 21..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "TableViewCell.h"
@interface TableViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *tTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *tDetailTextLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tImageView;

@end
@implementation TableViewCell

- (UILabel *)textLabel {
    return self.tTextLabel;
}
- (UILabel *)detailTextLabel {
    return self.tDetailTextLabel;
}
- (UIImageView *)imageView {
    return self.tImageView;
}
@end
