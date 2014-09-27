//
//  CGMusicViewController.m
//  ToBeDJ
//
//  Created by Yian Cheng on 7/11/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGMusicViewController.h"
#import <Parse/Parse.h>

@interface CGMusicViewController() <UIViewControllerRestoration>

typedef NS_ENUM(NSUInteger, NowPlayingStates) {
    StartedMediaPlayer = 0,
    UpdatesAllowed = 3,
    NoUpdatesAllowed = 4
};

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIView *volumeView;

// keep track of all previously played songs
@property (nonatomic) NSMutableArray* finishedIndices;

//0,1,2 means just started playing --> false; 3 means true; 4 means false
@property (nonatomic, assign) int canUpdate;

@property (nonatomic) NSTimer *timer;
- (void) checkIfTimeToSkip:(NSTimer *)timer;
@property (strong, nonatomic) NSString *nameFont;
@property (weak, nonatomic) IBOutlet UIButton *mediaPickerButton;
@property (nonatomic, strong) NSString *backgroundName;

- (void)registerMediaPlayerNotifications;

@end

@implementation CGMusicViewController

- (instancetype) init
{
    self = [super init];
    if (self) {
        
        // state restoration
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
    
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.backgroundName = @"background.jpg";

    if ([PFUser currentUser][@"masterDJ"] == [NSNumber numberWithBool:NO] || [PFUser currentUser][@"masterDJ"] == nil) {
        //Automatically shows media picker when you make the room
        [self showMediaPicker:self];

        //Set user to be a masterDJ; ensures that user can only be masterDJ of one room
        PFUser *user = [PFUser currentUser];
        user[@"masterDJ"] = [NSNumber numberWithBool:YES];
        [user saveInBackground];
    }

    _musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [_musicPlayer stop]; //Presents a new, empty music player; not the state that ipod is on

    // Music player plays songs in order that you selected them, and repeats playlist when you're done
    // we can decide to change defaults later
    _musicPlayer.shuffleMode = MPMusicShuffleModeOff;
    _musicPlayer.repeatMode = MPMusicRepeatModeAll;

    //Setup volume slider
    _volumeView.backgroundColor = [UIColor clearColor];
    MPVolumeView *volume = [[MPVolumeView alloc] initWithFrame:_volumeView.bounds];
    volume.showsVolumeSlider = YES;
    [_volumeView addSubview:volume];

    //    // set up trash icon
    //    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
    //                                                                                 target:self
    //                                                                                 action:@selector(deleteButtonPressed:)];
    //    self.navigationItem.rightBarButtonItem = rightButton;

    self.canUpdate = 0;
    self.finishedIndices = [[NSMutableArray alloc] init];

    [self registerMediaPlayerNotifications];

    // UI initialization
    self.nameFont = @"Avenir";
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    MPMediaItemArtwork *artwork = [[_musicPlayer nowPlayingItem] valueForProperty:MPMediaItemPropertyArtwork];
    if (artwork) {
        UIImage *artworkImage = [artwork imageWithSize:CGSizeMake(200, 200)];
        UIColor *albumBackground = [[UIColor colorWithPatternImage:artworkImage] colorWithAlphaComponent:0.8f];
        self.view.backgroundColor = albumBackground;
    } else {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
    }

    _titleLabel.textColor = [UIColor whiteColor];
    _albumLabel.textColor = [UIColor whiteColor];
    _artistLabel.textColor = [UIColor whiteColor];

    UIFont *labelFont = [UIFont fontWithName:self.nameFont size:16];
    _titleLabel.font = [labelFont fontWithSize:29];
    _albumLabel.font = labelFont;
    _artistLabel.font = labelFont;
    _mediaPickerButton.titleLabel.font = labelFont;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                  target:self
                                                selector:@selector(checkIfTimeToSkip:)
                                                userInfo:nil
                                                 repeats:YES];
}

#pragma mark Media Picker

//Present new view of all songs in user music library; user will select which songs to play
- (IBAction)showMediaPicker:(id)sender {
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = YES;
    mediaPicker.prompt = @"Select songs to play";
    
    [self presentViewController:mediaPicker animated:YES completion:NULL];
}

//Dismiss media picker view controller; if user has selected songs, start playing the songs
- (void) mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    if (mediaItemCollection) {
        [self.mediaItemCollection removeAllObjects];
        self.mediaItemCollection = [NSMutableArray arrayWithArray:mediaItemCollection.items];
        [_musicPlayer setQueueWithItemCollection:mediaItemCollection];
        [_musicPlayer play];
        [_playPauseButton setImage:[UIImage imageNamed:@"pause-button.png"] forState:UIControlStateNormal];
        [self updatePlayerItems];
        
        // if app has been closed/crashed, retrieve roomOwner and songQueue information
        if (!self.roomOwner)
        {
            PFQuery *query = [PFQuery queryWithClassName:@"Room"];
            [query whereKey:@"masterDJ" equalTo:[PFUser currentUser]];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                self.roomOwner = object;
                [object fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    [object[@"songQueue"] removeAllObjects];
                    [object saveInBackground];
                    [self makePlaylist];
                    [self setNowPlayingAsCurrent];
                }];
            }];
        }
        else {
            [self makePlaylist];
            [self setNowPlayingAsCurrent];
        }
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:NO completion:NULL];
}


#pragma mark - User Actions Affecting Media

//Play/pause music and changes button image to reflect state
- (IBAction)playPause:(id)sender {
    if ([_musicPlayer playbackState] == MPMusicPlaybackStatePlaying) {
        [_playPauseButton setImage:[UIImage imageNamed:@"play-button.png"] forState:UIControlStateNormal];
        [_musicPlayer pause];
    } else {
        [_playPauseButton setImage:[UIImage imageNamed:@"pause-button.png"] forState:UIControlStateNormal];
        [_musicPlayer play];
    }
}

- (IBAction)nextSong:(id)sender
{
    self.canUpdate = NoUpdatesAllowed;
    [self updateCurrentAndUpcoming];
    [self updatePlayerItems];
    [self setNowPlayingAsCurrent];
}

- (IBAction)prevSong:(id)sender
{
    self.canUpdate = NoUpdatesAllowed;
    
    if ([self.finishedIndices count] > 0)
    {
        // grab index of previously played song
        NSNumber* currentIndex = self.roomOwner[@"currentSongIndex"];
        NSNumber* previousIndex = [self.finishedIndices lastObject];
        [self.finishedIndices removeLastObject];
        
        // keep removing if finished index is the same (happens in scenarios where next button didn't update because Parse too slow)
        if ([self.finishedIndices lastObject])
        {
            while ([previousIndex isEqualToNumber: [self.finishedIndices lastObject]]) {
                [self.finishedIndices removeLastObject];
            }
        }
        
        // play previous song
        [_musicPlayer pause];
        if (![previousIndex isEqualToNumber:@0]) {
            _musicPlayer.nowPlayingItem = self.mediaItemCollection[[previousIndex intValue]]; // note that intValue gives nil if index is 0...
        }
        else {
            _musicPlayer.nowPlayingItem = self.mediaItemCollection[0];
        }
        [_musicPlayer play];
        self.roomOwner[@"upcomingSongIndex"] = currentIndex;
        self.roomOwner[@"newSong"] = @YES;
        [self.roomOwner saveInBackground];
    }
//    [self setNowPlayingAsCurrent];
}

// called when the delete button is pressed
//- (void)deleteButtonPressed:(id)sender
//{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to delete this room?"
//                                                    message:@"You'll shut down the party for everyone else."
//                                                   delegate:self
//                                          cancelButtonTitle:@"Cancel"
//                                          otherButtonTitles:@"Delete", nil];
//    [alert show];
//}
//
//// alter actions based on what the user clicks in the alertview
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex == 0) {
//        // do nothing if they hit "cancel"
//        return;
//    } else {
//        // delete the room if they didn't
//        [self deleteRoom];
//    }
//}

#pragma mark Other

- (void) checkIfTimeToSkip:(NSTimer *)timer
{
    BOOL userIsDJ = [[PFUser currentUser][@"masterDJ"] boolValue];
    if (userIsDJ) { // only run the query if the user owns a room
        PFQuery *query = [PFQuery queryWithClassName:@"Room"];
        [query whereKey:@"masterDJ" equalTo:[PFUser currentUser]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *room, NSError *error) {
            if (!error) {
                BOOL test = [room[@"readyToSkip"] boolValue];
                if (test == YES) {
                    room[@"readyToSkip"] = @NO;
                    [room saveInBackground];
                    self.canUpdate = NoUpdatesAllowed;
                    [self updateCurrentAndUpcoming];
                    [self setNowPlayingAsCurrent];
                }
            }
        }];
    }
}

//// query to find the old room and delete it
//- (void)deleteRoom
//{
//    //Finds the old room and deletes it
//    PFQuery *query = [PFQuery queryWithClassName:@"Room"];
//    [query whereKey:@"masterDJ" equalTo:[PFUser currentUser]];
//    [query getFirstObjectInBackgroundWithBlock:^(PFObject *room, NSError *error) {
//        if (!error) {
//            [room deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                [PFObject deleteAllInBackground:room[@"songQueue"]];
//            }];
//        }
//    }];
//
//    // stop the music player
//    [self.musicPlayer stop];
//
//    //Set masterDJ status for current user to false
//    [PFUser currentUser][@"masterDJ"] = [NSNumber numberWithBool:NO];
//    [[PFUser currentUser] saveInBackground];
//
//    // send back to the main screen
//    [self.navigationController popToRootViewControllerAnimated:YES];
//}

//Update view items to reflect new data (artwork image, title, artist, album) of song being played; called each time user changes media
- (void)updatePlayerItems
{
    MPMediaItem *currentItem = [_musicPlayer nowPlayingItem];
    
    UIImage *artworkImage = [UIImage imageNamed:@"noArtworkImage.png"];
    MPMediaItemArtwork *artwork = [currentItem valueForProperty:MPMediaItemPropertyArtwork];
    if (artwork) {
        artworkImage = [artwork imageWithSize:CGSizeMake(200, 200)];
        UIColor *albumBackground = [UIColor colorWithPatternImage:artworkImage];
        albumBackground = [albumBackground colorWithAlphaComponent:0.8f];
        self.view.backgroundColor = albumBackground;
    }
    
    NSString *titleString = [currentItem valueForProperty:MPMediaItemPropertyTitle];
    if (titleString) {
        _titleLabel.text = [NSString stringWithFormat:@"%@", titleString];
    } else {
        _titleLabel.text = @"Unknown title";
    }
    
    NSString *artistString = [currentItem valueForProperty:MPMediaItemPropertyArtist];
    if (artistString) {
        _artistLabel.text = [NSString stringWithFormat:@"%@", artistString];
    } else {
        _artistLabel.text = @"Unknown artist";
    }
    
    NSString *albumString = [currentItem valueForProperty:MPMediaItemPropertyAlbumTitle];
    if (albumString) {
        _albumLabel.text = [NSString stringWithFormat:@"%@", albumString];
    } else {
        _albumLabel.text = @"Unknown album";
    }
    
}

- (void)makePlaylist
{
    NSMutableArray *tempSongQueue = [[NSMutableArray alloc] init];

    // remomve current objects, for if songs chosen after playlist already exists -- in future, we should make it so that the DJ can add songs instead
    if ([self.roomOwner[@"songQueue"] count] > 0)
    {
        self.canUpdate = StartedMediaPlayer;
        [self.roomOwner[@"songQueue"] removeAllObjects];
    }
    
    // making self.mediaItemCollection in JSON format to be saved on Parse as an array of Songs
    for (int i = 0; i < [self.mediaItemCollection count]; i++) {
        MPMediaItem *mediaItem = self.mediaItemCollection[i];
        PFObject *song = [PFObject objectWithClassName:@"Song"];
        
        song[@"songTitle"] = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
        song[@"songArtist"] = [mediaItem valueForProperty:MPMediaItemPropertyArtist];
        song[@"albumName"] = [mediaItem valueForProperty:MPMediaItemPropertyAlbumTitle];
        
        UIImage *artworkImage = [UIImage imageNamed:@"noArtworkImage.png"];
        MPMediaItemArtwork *artwork = [mediaItem valueForProperty:MPMediaItemPropertyArtwork];
        if (artwork) {
            artworkImage = [artwork imageWithSize:CGSizeMake(200, 200)];
        }
        NSData *imageData = UIImagePNGRepresentation(artworkImage);
        PFFile *imageFile = [PFFile fileWithData:imageData];
        [imageFile saveInBackground];
        song[@"albumArtwork"] = imageFile;
        
        song[@"upVotes"] = @0;
        song[@"downVotes"] = @0;
        
        [song saveInBackground];
        
        // add song with above info to songQueue array in room
//        [self.roomOwner addUniqueObject:song forKey:@"songQueue"]; //- SEEMS TO BE OUT OF ORDER SOMETIMES, MAYBE BECAUSE SLOW?
        [tempSongQueue addObject:song];
    }
    
    self.roomOwner[@"currentSongIndex"] = @0;
    if ([tempSongQueue count] < 2)
    {
        
        self.roomOwner[@"upcomingSongIndex"] = @0; // only plays first and only song
    }
    else
    {
        self.roomOwner[@"upcomingSongIndex"] = @1;
    }

    self.roomOwner[@"songQueue"] = tempSongQueue;
    [self.roomOwner saveInBackground];
}

- (void)setNowPlayingAsCurrent
{
    if (self.roomOwner[@"songQueue"] && (_musicPlayer.indexOfNowPlayingItem < [self.roomOwner[@"songQueue"] count])) {
        // currentSong field is actually unnecessary now
        self.roomOwner[@"currentSong"] = self.roomOwner[@"songQueue"][_musicPlayer.indexOfNowPlayingItem];
        self.roomOwner[@"currentSongIndex"] = @(_musicPlayer.indexOfNowPlayingItem);
        [_roomOwner saveInBackground];
    }
}

/* TO BE IMPROVED LATER, use when we want to change song order based on votes by changing order of songQueue/mediaItemCollection/currentSongIndex */
- (void)updateCurrentAndUpcoming
{
    // Note: since makePlaylist is slow, upcoming and currentSongIndex aren't updated fast enough if you click next immediately so it'll replay the second until Parse updates

    // grab indices
    int finishedIndex = [self.roomOwner[@"currentSongIndex"] intValue]; // note that intValue gives nil for 0...in case there are bugs later. though adding nil somehow still adds 0 to the array and on Parse.
    [self.finishedIndices addObject:@(finishedIndex)];
    int upcomingBecomingCurrent;
    if (self.roomOwner)
    {
        upcomingBecomingCurrent = [self.roomOwner[@"upcomingSongIndex"] intValue];
    }
    else
    {
        PFQuery *query = [PFQuery queryWithClassName:@"Room"];
        [query whereKey:@"masterDJ" equalTo:[PFUser currentUser]];
        self.roomOwner = [query getFirstObject];
    }

    // change now playing to upcoming song
    [_musicPlayer pause];
    //self.canUpdate = NoUpdatesAllowed; // to prevent updateCurrentandUpcoming from being called again
    _musicPlayer.nowPlayingItem = self.mediaItemCollection[upcomingBecomingCurrent];
    [_musicPlayer play];

    // reset former current song's upvotes and downvotes to 0
    PFObject *finishedSong = self.roomOwner[@"songQueue"][finishedIndex];
    finishedSong[@"upVotes"] = @0;
    finishedSong[@"downVotes"] = @0;
    [finishedSong saveInBackground];

    // update currentSong and currentSongIndex on parse to nowplaying -- actually this is done in nowPlayingItemChanged
//    [self updatePlayerItems];
//    [self setNowPlayingAsCurrent];

    if (self.roomOwner[@"songQueue"])
    {
        [self.roomOwner refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {

            [PFObject fetchAllIfNeededInBackground:self.roomOwner[@"songQueue"] block:^(NSArray *objects, NSError *error) {

                // update upcomingSongIndex to most popular song
                int count = (int)[objects count];
                NSNumber *highestScore = @0;
                NSNumber *highestIndex = @0;
                for (int i = 0; i < count; i++)
                {
                    if (i != finishedIndex && i != upcomingBecomingCurrent)
                    {
                        PFObject *song = objects[i];
                        NSNumber *score = @([song[@"upVotes"] intValue] - [song[@"downVotes"] intValue]);
                        if ([score intValue] > [highestScore intValue])
                        {
                            highestScore = score;
                            highestIndex = @(i);
                        }
                    }
                }

                // if no votes on any songs, increment upcomingSongIndex anyways so it doesn't keep playing same song
                if ([highestScore isEqualToNumber:@0])
                {
                    self.roomOwner[@"upcomingSongIndex"] = @(((upcomingBecomingCurrent+1) % count));
                }
                else
                {
                    self.roomOwner[@"upcomingSongIndex"] = highestIndex;
                }
                
                
                // HMMM... do we ever reset this to @NO?
                self.roomOwner[@"newSong"] = @YES;
                [self.roomOwner saveInBackground];
            }];
        }];
    }
}

- (void)registerMediaPlayerNotifications
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(nowPlayingItemChanged:)
               name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
             object:_musicPlayer];
    [_musicPlayer beginGeneratingPlaybackNotifications];
}

- (void)nowPlayingItemChanged:(id)notification
{
    //0,1,2 means just started playing --> false; 3 means true; 4 means false
    if (self.canUpdate < UpdatesAllowed)
    {
        self.canUpdate++;
        return;
    }

    if (self.canUpdate == UpdatesAllowed)
    {
        [self updateCurrentAndUpcoming];
        [self updatePlayerItems];
        [self setNowPlayingAsCurrent];
    }
    else if (self.canUpdate == NoUpdatesAllowed)
    {
        self.canUpdate = UpdatesAllowed;
    }
    else
    {
    }
    [self updatePlayerItems];
    [self setNowPlayingAsCurrent];

}

#pragma mark State Restoration
+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

@end
