//
//  CGSongHeaderViewController.m
//  ToBeDJ
//
//  Created by Kimberley Yu on 8/1/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

// NOTE: Ideally we would implement push notifications in the future so that the phone with the musicViewController would send notification that nowPlayingItem changed, instead of pulling from Parse every 0.25 seconds with NSTimer.

#import "CGSongHeaderViewController.h"

#import <Parse/Parse.h>

#import "CGSongCell.h"

@interface CGSongHeaderViewController () <UIViewControllerRestoration>
// to hold array of songs from Parse so you don't have to pull all the time
@property (strong, nonatomic) NSMutableArray *songCache;
// key = song ID or album name; value = image -- so that even if order of songs changes, you already have the image cached
@property (strong, nonatomic) NSMutableDictionary *imgCache;

@property (nonatomic, assign) NSTimer *timer;
- (void) updateSong:(NSTimer *)timer;

// method to pull and save the songs in songCache array each time song order changes
- (void) cacheSongs;

// UI label to alter font
@property (weak, nonatomic) IBOutlet UILabel *currentSongLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentArtistLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentAlbumLabel;
@property (weak, nonatomic) IBOutlet UILabel *upcomingLabel;
@property (weak, nonatomic) IBOutlet UILabel *upcomingSongLabel;
@property (weak, nonatomic) IBOutlet UILabel *upcomingArtistLabel;
@property (weak, nonatomic) IBOutlet UILabel *songBucketLabel;
@property (weak, nonatomic) IBOutlet UILabel *upcomingAlbumLabel;
@property (strong, nonatomic) NSString *nameFont;

//Voting buttons
@property (strong, nonatomic) IBOutlet UIButton *currentSongUpVoteButton;
@property (strong, nonatomic) IBOutlet UIButton *currentSongDownVoteButton;
@property (strong, nonatomic) IBOutlet UIButton *upcomingSongUpVoteButton;
@property (strong, nonatomic) IBOutlet UIButton *upcomingSongDownVoteButton;


//Voting actions
- (IBAction)currentSongUpVote:(id)sender;
- (IBAction)currentSongDownVote:(id)sender;
- (IBAction)upcomingSongUpVote:(id)sender;
- (IBAction)upcomingSongDownVote:(id)sender;

@end


@implementation CGSongHeaderViewController

#pragma mark Initializing
- (instancetype)init
{
    self = [super init];
    if (self) {
        // state restoration
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        
        _songCache = [[NSMutableArray alloc] init];
        _imgCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // initialize labels
    _nameFont = @"Avenir";
    _currentSongLabel.font = [UIFont fontWithName:_nameFont size:24];
    _currentArtistLabel.font = [UIFont fontWithName:_nameFont size:16];
    _currentAlbumLabel.font = [UIFont fontWithName:_nameFont size:16];
    _upcomingLabel.font = [UIFont fontWithName:_nameFont size:18];
    _upcomingSongLabel.font = [UIFont fontWithName:_nameFont size:18];
    _upcomingArtistLabel.font = [UIFont fontWithName:_nameFont size:12];
    _upcomingAlbumLabel.font = [UIFont fontWithName:_nameFont size:12];
    _songBucketLabel.font = [UIFont fontWithName:_nameFont size:18];
    
    // pulls songs from parse and saves in array; pulls images also into dictionary -- only need to pull song assuming no new songs can be added to playlist...
    [self cacheSongs];
    
    UINib *cellNib = [UINib nibWithNibName:@"CGSongCell" bundle:nil];
    [_songBucketTableView registerNib:cellNib forCellReuseIdentifier:@"CGSongCell"];
    _songBucketTableView.delegate = self;
    _songBucketTableView.dataSource = self;
    _songBucketTableView.restorationIdentifier = @"CGSongHeaderViewController";
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //NSTimer updating song info displayed every 0.25 seconds
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                              target:self
                                            selector:@selector(updateSong:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if([_timer isValid])
    {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark Voting

- (IBAction)currentSongUpVote:(id)sender
{
    PFObject *song = self.roomOwner[@"currentSong"];
    
    [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {

        if (_currentSongUpVoteButton.enabled) {
            [song incrementKey:@"upVotes"];
            _currentSongUpVoteButton.enabled = NO;
            
            if (_currentSongDownVoteButton.enabled == NO) {
                [song incrementKey:@"downVotes" byAmount:[NSNumber numberWithInt:-1]];
            }
            
            _currentSongDownVoteButton.enabled = YES;
            
            
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

- (IBAction)currentSongDownVote:(id)sender
{
    PFObject *song = self.roomOwner[@"currentSong"];
    
    [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error){
        //Increment down votes, disables down vote button, enables up vote button
        if (_currentSongDownVoteButton.enabled) {
            
            [song incrementKey:@"downVotes"];
            _currentSongDownVoteButton.enabled = NO;
            
            //If originally up voted, decrement up vote;
            if (_currentSongUpVoteButton.enabled == NO) {
                [song incrementKey:@"upVotes" byAmount:[NSNumber numberWithInt:-1]];
            }
            
            _currentSongUpVoteButton.enabled = YES;
            
            
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

- (IBAction)upcomingSongUpVote:(id)sender
{
    PFObject *song = self.songCache[[self.roomOwner[@"upcomingSongIndex"] intValue]];
    [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if (_upcomingSongUpVoteButton.enabled) {
            [song incrementKey:@"upVotes"];
            _upcomingSongUpVoteButton.enabled = NO;
            
            if (_upcomingSongDownVoteButton.enabled == NO) {
                [song incrementKey:@"downVotes" byAmount:[NSNumber numberWithInt:-1]];
            }
            
            _upcomingSongDownVoteButton.enabled = YES;
            
            
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

- (IBAction)upcomingSongDownVote:(id)sender
{
    PFObject *song = self.songCache[[self.roomOwner[@"upcomingSongIndex"] intValue]];
    [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error){
        //Increment down votes, disables down vote button, enables up vote button
        if (_upcomingSongDownVoteButton.enabled) {
            
            [song incrementKey:@"downVotes"];
            _upcomingSongDownVoteButton.enabled = NO;
            
            //If originally up voted, decrement up vote;
            if (_upcomingSongUpVoteButton.enabled == NO) {
                [song incrementKey:@"upVotes" byAmount:[NSNumber numberWithInt:-1]];
            }
            
            _upcomingSongUpVoteButton.enabled = YES;
            
            
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

#pragma mark Song Table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_roomOwner[@"songQueue"] count];
}

// make height of cell 0 if it is current/upcoming song (to hide the cell)
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDecimalNumber *currentSongIndex = self.roomOwner[@"currentSongIndex"];
    NSDecimalNumber *upcomingSongIndex = self.roomOwner[@"upcomingSongIndex"];
    if (indexPath.row == [currentSongIndex intValue] || indexPath.row == [upcomingSongIndex intValue])
    {
        return 0.0f;
    }
    return 75.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSongCell *cell = (CGSongCell *)[tableView dequeueReusableCellWithIdentifier:@"CGSongCell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[CGSongCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CGSongCell"];
    }
    
    // set album artwork to be that of matching song in imgCache dictionary
    
    if (self.songCache.count > 2) {
        NSDecimalNumber *currentSongIndex = self.roomOwner[@"currentSongIndex"];
        NSDecimalNumber *upcomingSongIndex = self.roomOwner[@"upcomingSongIndex"];
        if (indexPath.row == [currentSongIndex intValue] || indexPath.row == [upcomingSongIndex intValue])
        {
            // TODO disable voting buttons
            
            
            cell.songTitle.text = @"";
            cell.artistName.text = @"";
            cell.albumName.text = @"";
            cell.songId = @"";
            return cell;
        }
        
        PFObject *song = self.songCache[indexPath.row];
        if (song.isDataAvailable) {
            //UIImage *img = self.imgCache[song.objectId];
            //cell.albumArtwork.image = img;
            cell.songTitle.text = song[@"songTitle"];
            cell.artistName.text = song[@"songArtist"];
            NSString *dash = @"— ";
            NSString *albumName = [dash stringByAppendingString:song[@"albumName"]];
            cell.albumName.text = albumName;
            // just for testing
            cell.songId = [song objectId];
        }
    }
    
    return cell;
}


#pragma mark Parse Data
// updates songCache array property each time song order changes
- (void) cacheSongs
{
    [self.songCache removeAllObjects];

    [self.roomOwner refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            //find succeeded
            for (PFObject *song in self.roomOwner[@"songQueue"]) {
                [self.songCache addObject:song];

                // Only cache images on first load of songs; will add cacheDone key to dictionary when done saving images
                if (![self.imgCache objectForKey:@"cacheDone"])
                {
                    [song fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {

                        // sync album artwork
                        PFFile *imageFile = song[@"albumArtwork"];

                        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                            UIImage *image = [UIImage imageWithData:data];
                            if (image)
                            {
                                [self.imgCache setObject:image forKey:song.objectId];
                            }
                            else
                            {
                                // set artwork as jukebox logo if no artwork available
                                [self.imgCache setObject:[UIImage imageNamed:@"jukebox-logo.png"] forKey:song.objectId];

                            }


                            // after imgCache is done the first time, add cacheDone key
                            if ([self.imgCache count] == [self.songCache count])
                            {
                                [self.imgCache setValue:@"done" forKey:@"cacheDone"];

                                // notification to update header; fix later?
                                [self updateSong:self.timer];
                                [_songBucketTableView reloadData];
                            }
                        }];
                    }];
                }
            }

        } else {
            NSLog(@"Error: %@", self.songCache);
        }
    }];
}

// update current and upcoming songs
-(void)updateSong:(NSTimer *)timer
{
    [self.songBucketTableView reloadData];
    
    [self.roomOwner refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (self.songCache.count > 0)
        {
            // set current song
            PFObject *current = self.songCache[[object[@"currentSongIndex"] intValue]];
            if (current.isDataAvailable)
            {
                // actually I don't need to check this anymore because I am now adding a "No Album Artwork" UIImage to the imgCache now instead of string. but leaving this anyways just in case
                if ([self.imgCache[current.objectId] isKindOfClass:[UIImage class]]){
                    UIImage* img = self.imgCache[current.objectId];
                    _currentAlbumArt.image = img;
                }
                else {
                    _currentAlbumArt.image = nil;
                }
                _currentSong.text = current[@"songTitle"];
                _currentArtist.text = current[@"songArtist"];
                _currentAlbum.text = current[@"albumName"];
            }

            if (self.songCache.count > 1)
            {
                // set upcoming song
                PFObject *upcoming = self.songCache[[object[@"upcomingSongIndex"] intValue]];

                if (upcoming.isDataAvailable)
                {
                    if ([self.imgCache[upcoming.objectId] isKindOfClass:[UIImage class]]){
                        UIImage *img2 = self.imgCache[upcoming.objectId];
                        _upcomingAlbumArt.image = img2;
                    }
                    else {
                        _upcomingAlbumArt.image = nil;
                    }
                    _upcomingSong.text = upcoming[@"songTitle"];
                    _upcomingArtist.text = upcoming[@"songArtist"];
                    _upcomingAlbum.text = upcoming[@"albumName"];
                }
            }
        }
    }];
}

#pragma mark State Restoration
+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

@end
