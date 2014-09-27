//
//  CGRoomCell.m
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/14/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGRoomCell.h"

@interface CGRoomCell ()

@property (nonatomic, strong) NSString *nameFont;
@property (nonatomic, strong) UIFont *mainFont;
@property (nonatomic, strong) UIFont *titleFont;

@end

@implementation CGRoomCell

- (void)awakeFromNib
{
    // Initialization code
    self.nameFont = @"Avenir";

    self.mainFont = [UIFont fontWithName:_nameFont size:12];
    self.nameDJLabel.font = self.mainFont;
    self.numOccupants.font = self.mainFont;

    self.titleFont = [UIFont fontWithName:_nameFont size:36];
    self.roomCellName.font = self.titleFont;
    self.roomCellName.textColor = [UIColor whiteColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
