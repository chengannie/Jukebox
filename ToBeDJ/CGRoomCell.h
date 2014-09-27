//
//  CGRoomCell.h
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/14/14.
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@class CGRoom;

@interface CGRoomCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *roomAvatar;
@property (weak, nonatomic) IBOutlet UILabel *roomCellName;
@property (weak, nonatomic) IBOutlet UILabel *nameDJLabel;
@property (weak, nonatomic) IBOutlet UILabel *numOccupants;

@property (weak, nonatomic) CGRoom *roomObject;

@end
