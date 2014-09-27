//
//  CGMusicViewController.h
//  ToBeDJ
//
//  Created by Yian Cheng on 7/11/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Parse/Parse.h>

@interface CGMusicViewController : UIViewController <MPMediaPickerControllerDelegate, UIAlertViewDelegate>

@property PFObject *roomOwner;
@property (nonatomic, assign) MPMusicPlayerController *musicPlayer; //make private?
@property (nonatomic, strong) NSMutableArray *mediaItemCollection;
//@property (nonatomic) NSUInteger currentSongIndex;

- (IBAction)showMediaPicker:(id)sender;
- (IBAction)prevSong:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)nextSong:(id)sender;
- (void)updatePlayerItems;
- (void)makePlaylist;
//- (void)deleteRoom;

@end
