//
//  CGSongCell.h
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/21/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CGSongCell : UITableViewCell

@property (strong, nonatomic) NSString *songId;
// album artwork now only displayed for current and upcoming song
@property (weak, nonatomic) IBOutlet UIImageView *albumArtwork;
@property (weak, nonatomic) IBOutlet UILabel *songTitle;
@property (weak, nonatomic) IBOutlet UILabel *artistName;
@property (weak, nonatomic) IBOutlet UILabel *albumName;

@property (weak, nonatomic) IBOutlet UILabel *rank;

@end
