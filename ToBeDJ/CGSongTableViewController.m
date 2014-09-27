//
//  CGSongCollectionViewController.m
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/21/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <Parse/Parse.h>
#import "CGSongTableViewController.h"
#import "CGSongCell.h"
#import "CGSongHeaderViewController.h"

@interface CGSongTableViewController ()

// to hold array of songs from Parse so you don't have to pull all the time
@property (strong, nonatomic) NSMutableArray *songCache;
// key = song ID or album name; value = image -- so that even if order of songs changes, you already have the image cached
@property (strong, nonatomic) NSMutableDictionary *imgCache;
@property (nonatomic, retain) CGSongHeaderViewController *header;

@property (nonatomic, assign) NSTimer *timer;
- (void) updateSong:(NSTimer *)timer;

// method to pull and save the songs in songCache array each time song order changes
- (void) cacheSongs;

@property (nonatomic, strong) NSMutableDictionary *songVotes;

@end

@implementation CGSongTableViewController

#pragma mark - Initializers

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        
        self.songCache = [[NSMutableArray alloc] init];
        self.imgCache = [[NSMutableDictionary alloc] init];
        
    }
    
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    [self.tableView registerClass:[CGSongCell class] forCellReuseIdentifier:@"CGSongCell"];
    
    // pulls songs from parse and saves in array; pulls images also into dictionary -- only need to pull song assuming no new songs can be added to playlist...
    [self cacheSongs];
    
    //delete later?
    // Do any additional setup after loading the view from its nib.
    UINib *cellNib = [UINib nibWithNibName:@"CGSongCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CGSongCell"];
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

#pragma mark - Table View datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.roomOwner[@"songQueue"] count];
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
    
    //(A side note, if our app allowed users to add, remove or rearrange photos, we wouldn't even be able to assume that the original index path is still valid, instead we would also need to look that up again based on the specific album and photo.)
    
    if (self.songCache.count > 2) {
        // skip displaying current and upcoming song
//        if (self.roomOwner[@"newSong"]
//        int index = [self getSongIndex:indexPath];
        NSDecimalNumber *currentSongIndex = self.roomOwner[@"currentSongIndex"];
        NSDecimalNumber *upcomingSongIndex = self.roomOwner[@"upcomingSongIndex"];
        if (indexPath.row == [currentSongIndex intValue] || indexPath.row == [upcomingSongIndex intValue])
        {
            cell.songTitle.text = @"";
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
            cell.rank.text = [NSString stringWithFormat:@"%lu", (long)indexPath.row];
            
//            // add this index as already being displayed
//            [self.displayedIndices addObject:@(index)];
        }
    }
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    self.header = [[CGSongHeaderViewController alloc] init];
    
    [self updateSong:self.timer];
    
    return self.header.view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 270.0f;
}

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
                            NSLog(@"printing??? %@", image);
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
                                [self.tableView reloadData];
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
    // add back in later after Annie transfers her stuff
    //[self.tableView reloadData];
    
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
                    self.header.currentAlbumArt.image = img;
                }
                else {
                    self.header.currentAlbumArt.image = nil;
                }
                self.header.currentSong.text = current[@"songTitle"];
                self.header.currentArtist.text = current[@"songArtist"];
                self.header.currentAlbum.text = current[@"albumName"];
            }
            
            if (self.songCache.count > 1)
            {
                // set upcoming song
                PFObject *upcoming = self.songCache[[object[@"upcomingSongIndex"] intValue]];
                
                if (upcoming.isDataAvailable)
                {
                    if ([self.imgCache[upcoming.objectId] isKindOfClass:[UIImage class]]){
                        UIImage *img2 = self.imgCache[upcoming.objectId];
                        self.header.upcomingAlbumArt.image = img2;
                    }
                    else {
                        self.header.upcomingAlbumArt.image = nil;
                    }
                    self.header.upcomingSong.text = upcoming[@"songTitle"];
                    self.header.upcomingArtist.text = upcoming[@"songArtist"];
                    self.header.upcomingAlbum.text = upcoming[@"albumName"];
                }
            }
        }
    }];
}

@end
