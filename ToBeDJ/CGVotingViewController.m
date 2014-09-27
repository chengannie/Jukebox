//
//  CGVotingViewController.m
//  ToBeDJ
//
//  Created by Yian Cheng on 7/14/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGVotingViewController.h"

#import <Parse/Parse.h>

#import "CGMusicViewController.h"

@interface CGVotingViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *albumArt;
@property (weak, nonatomic) IBOutlet UILabel *songTitle;
@property (weak, nonatomic) IBOutlet UILabel *artistName;
@property (weak, nonatomic) IBOutlet UILabel *albumName;
@property (nonatomic) NSTimer *timer;
- (void) updateSong:(NSTimer *)timer;
@property (weak, nonatomic) IBOutlet UIButton *upVoteButton;
@property (weak, nonatomic) IBOutlet UIButton *downVoteButton;
@property (strong, nonatomic) NSString *nameFont;
@property (strong, nonatomic) NSString *backgroundName;

@end

@implementation CGVotingViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // initialize UI
    self.nameFont = @"Avenir";
    self.backgroundName = @"background.jpg";
    UIFont *labelFont = [UIFont fontWithName:self.nameFont size:16];
    self.songTitle.font = labelFont;
    self.artistName.font = labelFont;
    self.albumName.font = labelFont;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //NSTimer updating song info displayed every 0.1 seconds
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                      target:self
                                                    selector:@selector(updateSong:)
                                                    userInfo:nil
                                                     repeats:YES];
    
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    [runLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
//    [runLoop run];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if([self.timer isValid])
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

-(void)updateSong:(NSTimer *)timer
{
    [self.roomOwner refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        PFObject *song = self.roomOwner[@"currentSong"];
        [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {

            // set text on voting views
            self.songTitle.text = song[@"songTitle"];
            self.albumName.text = song[@"albumName"];
            self.artistName.text = song[@"songArtist"];
            
            // update score for song
            NSNumber *up = song[@"upVotes"];
            NSNumber *down = song[@"downVotes"];
            song[@"score"] = @([up floatValue] - [down floatValue]);
            [song saveInBackground];

            // see if the song has changed
            BOOL test = [self.roomOwner[@"newSong"] boolValue];
            if (test == YES) {
                self.roomOwner[@"newSong"] = @NO;
                self.upVoteButton.enabled = YES;
                self.downVoteButton.enabled = YES;
            }
            

            //TRYING TO UPDATE QUEUE
//            NSArray *queue = self.roomOwner[@"songQueue"];
//            NSMutableArray *resortedArray = [[NSMutableArray alloc] init];
//            for (int i = 0; i<[queue count] ; i++) {
//                NSLog(@"i = %d", i);
//                
//                [queue[i] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//                    [resortedArray addObject:queue[i]];
//                    NSLog(@"The resorted array has %lu items", (unsigned long)[resortedArray count]);
//                    
//                    if (i == ([queue count] - 1)) {
//                        NSLog(@"In if statement");
//                        NSArray *finalArray = [resortedArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//                            NSNumber *score1 = obj1[@"score"];
//                            NSNumber *score2 = obj2[@"score"];
//                            return [score1 compare:score2];
//                        }];
//                    
//                        NSLog(@"The final array has %lu items\n\n\n", (unsigned long)[finalArray count]);
//                    }
//                }];
//                
//            }

//            self.roomOwner[@"songQueue"] = finalArray;
//            [self.roomOwner saveInBackground];
            
            
            // sync album artwork
            PFFile *imageFile = song[@"albumArtwork"];
            [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                UIImage *image = [UIImage imageWithData:data];
                self.albumArt.image = image;
            }];
        }];
    }];
}

#pragma mark - Voting

- (IBAction)downVote:(id)sender
{
    PFObject *song = self.roomOwner[@"currentSong"];

    [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error){

        // get the song title/artist
        NSString *songTitle;
        NSString *songArtist;
        if (song[@"songTitle"]) {
            songTitle = song[@"songTitle"];
        }
        if (song[@"songArtist"]) {
            songArtist = song[@"songArtist"];
        }
        NSString *songString = [NSString stringWithFormat:@"'%@' by %@", songTitle, songArtist];

        //Increment down votes, disables down vote button, enables up vote button
        if (self.downVoteButton.enabled) {

            [song incrementKey:@"downVotes"];
            self.downVoteButton.enabled = NO;

            //If originally up voted, decrement up vote;
            if (self.upVoteButton.enabled == NO) {
                [song incrementKey:@"upVotes" byAmount:[NSNumber numberWithInt:-1]];
            }

            self.upVoteButton.enabled = YES;

            // store the song title/artist in dislikes
            [[PFUser currentUser] addObject:songString forKey:@"dislikes"];

            // save all data in the cloud
            [[PFUser currentUser] saveInBackground];
            [song saveInBackground];

            // check to see if we're ready to skip or not
            NSArray *arrayOfListeners = self.roomOwner[@"listeners"];
            NSUInteger numListeners = [arrayOfListeners count];
            NSUInteger numDownvotes = [song[@"downVotes"] intValue];
            if (numListeners == 1) {
                self.roomOwner[@"readyToSkip"] = @YES;
                [self.roomOwner saveInBackground];
            } else if (numDownvotes >= numListeners/2) {
                self.roomOwner[@"readyToSkip"] = @YES;
                [self.roomOwner saveInBackground];
            }
        }
    }];
}

// repeat most of the downvote code but for upvoting
- (IBAction)upVote:(id)sender
{
    PFObject *song = self.roomOwner[@"currentSong"];

    [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        NSString *songTitle;
        NSString *songArtist;
        if (song[@"songTitle"]) {
            songTitle = song[@"songTitle"];
        }
        if (song[@"songArtist"]) {
            songArtist = song[@"songArtist"];
        }
        NSString *songString = [NSString stringWithFormat:@"\"%@\" by %@", songTitle, songArtist];

        if (self.upVoteButton.enabled) {
            [song incrementKey:@"upVotes"];
            self.upVoteButton.enabled = NO;

            if (self.downVoteButton.enabled == NO) {
                [song incrementKey:@"downVotes" byAmount:[NSNumber numberWithInt:-1]];
            }

            self.downVoteButton.enabled = YES;

            [[PFUser currentUser] addUniqueObject:songString forKey:@"likes"];
            
            [[PFUser currentUser] saveInBackground];
            [song saveInBackground];
        }
    }];
}
@end
