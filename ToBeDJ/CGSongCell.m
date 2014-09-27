//
//  CGSongCell.m
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/21/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGSongCell.h"
#import <Parse/Parse.h>

@interface CGSongCell ()
@property (weak, nonatomic) IBOutlet UILabel *songNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumNameLabel;
@property (strong, nonatomic) IBOutlet UIButton *downVoteButton;
@property (strong, nonatomic) IBOutlet UIButton *upVoteButton;
@property (strong, nonatomic) NSString *nameFont;
@end

@implementation CGSongCell

- (instancetype)init
{
    if (self) {
        _nameFont = @"Avenir";
        _songNameLabel.font = [UIFont fontWithName:_nameFont size:22];
        _artistLabel.font = [UIFont fontWithName:_nameFont size:16];
        _albumNameLabel.font = [UIFont fontWithName:_nameFont size:16];
    }
    return self;
}

- (IBAction)upVote:(id)sender
{
    PFQuery *query = [PFQuery queryWithClassName:@"Song"];
    [query getObjectInBackgroundWithId:_songId block:^(PFObject *song, NSError *error) {
        if (_upVoteButton.enabled) {
            [song incrementKey:@"upVotes"];
            _upVoteButton.enabled = NO;
            
            if (_downVoteButton.enabled == NO) {
                [song incrementKey:@"downVotes" byAmount:[NSNumber numberWithInt:-1]];
            }
            
            _downVoteButton.enabled = YES;
            
            
            NSString *songTitle;
            NSString *songArtist;
            if (song[@"songTitle"]) {
                songTitle = song[@"songTitle"];
            }
            if (song[@"songArtist"]) {
                songArtist = song[@"songArtist"];
            }
            NSString *songString = [NSString stringWithFormat:@"'%@' by %@", songTitle, songArtist];
            [[PFUser currentUser] addUniqueObject:songString forKey:@"likes"];
            
            [[PFUser currentUser] saveInBackground];
            [song saveInBackground];
        }
    }];

        


}

- (IBAction)downVote:(id)sender
{
    PFQuery *query = [PFQuery queryWithClassName:@"Song"];
    [query getObjectInBackgroundWithId:_songId block:^(PFObject *song, NSError *error) {
        //Increment down votes, disables down vote button, enables up vote button
        if (_downVoteButton.enabled) {
            
            [song incrementKey:@"downVotes"];
            _downVoteButton.enabled = NO;
            
            //If originally up voted, decrement up vote;
            if (_upVoteButton.enabled == NO) {
                [song incrementKey:@"upVotes" byAmount:[NSNumber numberWithInt:-1]];
            }
            
            _upVoteButton.enabled = YES;
            
            
            // get the song title/artist and store in dislikes
            NSString *songTitle;
            NSString *songArtist;
            if (song[@"songTitle"]) {
                songTitle = song[@"songTitle"];
            }
            if (song[@"songArtist"]) {
                songArtist = song[@"songArtist"];
            }
            NSString *songString = [NSString stringWithFormat:@"'%@' by %@", songTitle, songArtist];
            [[PFUser currentUser] addObject:songString forKey:@"dislikes"];
            
            // save all data in the cloud
            [[PFUser currentUser] saveInBackground];
            [song saveInBackground];
        }
    }];
}

@end
