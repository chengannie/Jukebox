//
//  CGSongHeaderViewController.h
//  ToBeDJ
//
//  Created by Kimberley Yu on 8/1/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface CGSongHeaderViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) PFObject *roomOwner;

@property (weak, nonatomic) IBOutlet UIImageView *currentAlbumArt;
@property (weak, nonatomic) IBOutlet UILabel *currentSong;
@property (weak, nonatomic) IBOutlet UILabel *currentArtist;
@property (weak, nonatomic) IBOutlet UILabel *currentAlbum;

@property (weak, nonatomic) IBOutlet UIImageView *upcomingAlbumArt;
@property (weak, nonatomic) IBOutlet UILabel *upcomingSong;
@property (weak, nonatomic) IBOutlet UILabel *upcomingArtist;
@property (weak, nonatomic) IBOutlet UILabel *upcomingAlbum;
@property (strong, nonatomic) IBOutlet UILabel *songBucket;

@property (weak, nonatomic) IBOutlet UITableView *songBucketTableView;

@end
