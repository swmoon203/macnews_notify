//
//  FeedTableViewCell.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 12..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "FeedTableViewCell.h"

@implementation FeedTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UILabel *)textLabel {
    return self.titleText;
}

- (UIImageView *)imageView {
    return self.previewImage;
}
@end
