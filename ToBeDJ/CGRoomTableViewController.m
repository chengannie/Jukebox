//
//  CGRoomTableViewController.m
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/11/14.
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import "CGRoomTableViewController.h"

#import <Parse/Parse.h>

#import "CGAppDelegate.h"
#import "CGLoginViewController.h"
#import "CGMusicViewController.h"
#import "CGRoom.h"
#import "CGRoomCell.h"
#import "CGRoomDetailViewController.h"
#import "CGSongHeaderViewController.h"
#import "CGSongTableViewController.h"
#import "CGVotingViewController.h"
#import "SWRevealViewController.h"

@interface CGRoomTableViewController () //<UIViewControllerRestoration>

@property (strong, nonatomic) IBOutlet UITableView *roomsListView; //view for list of rooms
@property (nonatomic) NSArray *searchResults; // array of rooms that matches the search query
@property (nonatomic) UIRefreshControl *refreshControl;
@property NSString *roomToEnterName;

// NOTE: this method to keep music view controller is not very memory friendly
@property (nonatomic, retain) CGMusicViewController *deviceMusicView;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSString *nameFont;
@property (nonatomic, strong) NSString *backgroundName;

@property (nonatomic, strong) NSMutableArray *parseData;

// other methods
- (IBAction)createNewRoom:(id)sender;
- (void)refreshTable;

@end


@implementation CGRoomTableViewController

#pragma mark - Initializers

// the designated initializer
- (instancetype) init
{
    self = [super initWithStyle:UITableViewStylePlain];

    if (self) {
        _parseData = [[NSMutableArray alloc] init];

        // navigation bar set-up
        UINavigationItem *navItem = self.navigationItem;
        navItem.title = @"Jukebox Records";
        
        // state restoration
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:self
                                                                             action:@selector(createNewRoom:)];
        navItem.rightBarButtonItem= bbi;

        // initialize UI
        self.nameFont = @"Avenir";
        self.backgroundName = @"background.jpg";
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    // basic initialization of view
    [super viewDidLoad];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    // Load the NIB file and register it (don't delete this)
    UINib *nib = [UINib nibWithNibName:@"CGRoomCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"CGRoomCell"];
    self.tableView.restorationIdentifier = @"CGRoomTableViewController";

    // background color
    UIColor *bgRefreshColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];

    // Creating refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    [refreshControl setBackgroundColor:bgRefreshColor];
    self.refreshControl = refreshControl;
    [self.refreshControl setTintColor:[UIColor whiteColor]];

    // Creating view for extending background color
    CGRect frame = self.tableView.bounds;
    frame.origin.y = -frame.size.height;
    UIView* bgView = [[UIView alloc] initWithFrame:frame];
    bgView.backgroundColor = bgRefreshColor;

    // Adding the view below the refresh control
    [self.tableView insertSubview:bgView atIndex:0]; // This has to be after self.

    // initialize UI for search
    self.searchDisplayController.searchBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
    UITextField *searchField = [self.searchBar valueForKey:@"_searchField"];
    searchField.textColor = [UIColor whiteColor];
    searchField.keyboardAppearance = UIKeyboardAppearanceDark;
    searchField.font = [UIFont fontWithName:self.nameFont size:14];

    // load the data in
    [self refreshTable];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //Navigation bar UI setup
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:self.backgroundName] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.translucent = NO;
    UILabel *navigationBarTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    navigationBarTitleLabel.backgroundColor = [UIColor clearColor];
    navigationBarTitleLabel.textAlignment = NSTextAlignmentCenter;
    navigationBarTitleLabel.textColor = [UIColor whiteColor];
    navigationBarTitleLabel.text = @"Jukebox";
    navigationBarTitleLabel.font = [UIFont fontWithName:self.nameFont size:18];
    [navigationBarTitleLabel sizeToFit];
    self.navigationItem.titleView = navigationBarTitleLabel;

    // push the login view controller if the user isn't already logged in
    if ([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        // do nothing
    } else {
        // push the login view controller
        [self.navigationController pushViewController:[[CGLoginViewController alloc] init] animated:NO];
    }

    // set up the slide menu
    SWRevealViewController *revealController = [self revealViewController];
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];

    // set up the hamburger
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc]
                                         initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                         style:UIBarButtonItemStyleBordered
                                         target:revealController
                                         action:@selector(revealToggle:)];

    self.navigationItem.leftBarButtonItem = revealButtonItem;

}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // send the facebook request to pull profile data if it doesn't already exist
    if (![PFUser currentUser][@"profile"]) {
        FBRequest *request = [FBRequest requestForMe];
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {

                // pull the data from the request
                NSDictionary *userData = (NSDictionary*)result;
                NSString *facebookID = userData[@"id"];
                NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];

                // this will store any data that's displayed in the profile page that was pulled from facebook
                NSMutableDictionary *userProfile = [NSMutableDictionary dictionaryWithCapacity:10];

                // store data into each PFUser object
                if (facebookID) {
                    userProfile[@"facebookId"] = facebookID;
                }
                if (userData[@"name"]) {
                    userProfile[@"name"] = userData[@"name"];
                }
                if ([pictureURL absoluteString]) {
                    userProfile[@"pictureURL"] = [pictureURL absoluteString];
                }

                // store the data retrieved from facebook into parse
                [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
                [[PFUser currentUser] saveInBackground];
            }
        }];
        
    }
}

#pragma mark - Load Data Into Table

// called when data needs to be reloaded
- (void)refreshTable
{
    PFQuery *query = [PFQuery queryWithClassName:@"Room"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [_parseData removeAllObjects];
        for (int i = 0; i < [objects count]; i ++) {
            CGRoom *room = [[CGRoom alloc] init];
            room.name = objects[i][@"roomName"];
            room.masterDJName = objects[i][@"nameDJ"];
            room.masterDJObjectId = [objects[i][@"masterDJ"] objectId];
            NSArray *listenersList = objects[i][@"listeners"];
            room.listeners = (int)[listenersList count];
            room.roomParseObject = objects[i];
            
            PFObject *song = objects[i][@"currentSong"];
            [song fetchIfNeededInBackgroundWithBlock:^(PFObject * object, NSError *error) {
                if (object.isDataAvailable) {
                    // sync album artwork
                    PFFile *imageFile = object[@"albumArtwork"];
                    if (object[@"albumArtwork"]) {
                        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                            UIImage *image = [UIImage imageWithData:data];
                            room.currentSongImage = image;
                            if (error) {
                                NSLog(@"%@", error);
                            }
                            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
                            
                            [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
//                            [self.tableView reloadData];
                        }];
                    }
                }
            }];
            // this might add rooms out of order, depending on which load quickest? (hence our room table order keeps switching around)
            [_parseData addObject:room];

        }
        [self.tableView reloadData];
    }];

    // refresh the table & reload the view
    [self.refreshControl endRefreshing];
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.searchResults count];
    } else {
        return [_parseData count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRoomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CGRoomCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[CGRoomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CGRoomCell"];
        UIView *selectedBackground = [[UIView alloc] init];
        selectedBackground.backgroundColor = [UIColor redColor];
        cell.selectedBackgroundView = selectedBackground;
    }

    CGRoom *room = [[CGRoom alloc] init];
    cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        room = [self.searchResults objectAtIndex:indexPath.row];
    } else {
        room = [_parseData objectAtIndex:indexPath.row];
    }

    if (room.masterDJName) {
        NSString *key = @"DJ: ";
        NSString *keyAndValue = [key stringByAppendingString:room.masterDJName];
        cell.nameDJLabel.text = keyAndValue;
    }

    cell.roomCellName.text = room.name;
    BOOL hasOneListeners = NO;
    if (room.listeners == 1) {
        hasOneListeners = YES;
    }
    NSString *listeners = @"listeners";
    if (hasOneListeners) {
        listeners = @"listener";
    }
    cell.numOccupants.text = [NSString stringWithFormat: @"%d %@", room.listeners, listeners];

    if (room.currentSongImage) {
        cell.roomAvatar.image = room.currentSongImage;
    }
    else {
//        cell.roomAvatar.image = [UIImage imageNamed:@"jukebox-logo.png"];
        cell.roomAvatar.image = nil;
    }

    cell.roomObject = room;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRoomCell *cell = (CGRoomCell*) [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:0.05f];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *masterDJ = cell.roomObject.masterDJObjectId;
    NSString *currentUser = [[PFUser currentUser] objectId];

    // change the view if DJ vs listener
    if ([masterDJ isEqualToString:currentUser]) {
        // if DJ of the room, present the music controller
        if (self.deviceMusicView == NULL) {
            //if relaunching app, choose new music to play in room
            CGMusicViewController *mvc = [[CGMusicViewController alloc] init];
            self.deviceMusicView = mvc;
            [self.navigationController pushViewController:mvc animated:YES];
        } else {
            [self.navigationController pushViewController:self.deviceMusicView animated:YES];
        }
    } else {
        if ([cell.roomObject.roomParseObject[@"password"] isEqualToString:@""] || cell.roomObject.roomParseObject[@"password"] == nil) {
            //Room has no password, store user as listener of room in Parse, present voting view
            [cell.roomObject.roomParseObject addUniqueObject:currentUser forKey:@"listeners"];
            [cell.roomObject.roomParseObject saveInBackground];

            CGSongHeaderViewController *shvc = [[CGSongHeaderViewController alloc] init];
            shvc.roomOwner = cell.roomObject.roomParseObject;
            [self.navigationController pushViewController:shvc animated:YES];
        } else {
            //Present alert and ask user to enter password
            UIAlertView *passwordAlert = [[UIAlertView alloc] initWithTitle:@"Password required"
                                                                    message:@"Enter the password chosen by the DJ of the room"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"OK", nil];
            passwordAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
            passwordAlert.tag = 2;
            self.roomToEnterName = cell.roomObject.name;
            [passwordAlert show];
        }
    }
}

#pragma mark - Room Creation

/* Checks if user is already masterDJ of a room; if no, pushes detailViewController
 Else, provides the option to delete the old room and create a new one
 */
- (IBAction)createNewRoom:(id)sender
{
    PFUser *user = [PFUser currentUser];
    if (user[@"masterDJ"] == [NSNumber numberWithBool:YES]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to create a new room?"
                                                        message:@"Your current room will be deleted"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Delete", nil];
        alert.tag = 1;
        [alert show];
    } else {
        [self newRoom];
    }

}

/* Creates a new room, pushes detail view controller to screen, saves to Parse */
- (void)newRoom
{
    PFObject *newRoom = [PFObject objectWithClassName:@"Room"];

    CGRoomDetailViewController *detailViewController = [[CGRoomDetailViewController alloc] initForNewRoom:YES];
    detailViewController.currentRoom = newRoom;

    detailViewController.dismissBlock = ^{
        //Save room to Parse
        [self.tableView reloadData];
        [newRoom saveInBackground];

        //Pushes music view controller to screen
        CGMusicViewController *mvc = [[CGMusicViewController alloc] init];
        mvc.roomOwner = newRoom;
        self.deviceMusicView = mvc;
        [self.navigationController pushViewController:mvc animated:YES];
    };

    detailViewController.cancelBlock = ^{
        [self.tableView reloadData];
    };

    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:detailViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:NO completion:NULL];
}

// if you click delete on alert view
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //Alert for creating a new room; will delete old room and create a new room
    if (alertView.tag == 1) {
        if (buttonIndex == 0) {
            return;
        } else {
            //Finds the old room and deletes it
            PFQuery *query = [PFQuery queryWithClassName:@"Room"];
            [query whereKey:@"masterDJ" equalTo:[PFUser currentUser]];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error) {
                    [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [PFObject deleteAllInBackground:object[@"songQueue"]];
                    }];
                }
            }];
            [self.deviceMusicView.musicPlayer stop];
            [self.deviceMusicView.musicPlayer endGeneratingPlaybackNotifications];

            // trying to delete the previous musicViewController...though it doesn't work. there are probs other references to it. or retain just keeps it from ever being deleted :P
            self.deviceMusicView = nil;
            //[self.deviceMusicView dismissViewControllerAnimated:YES completion:nil];

            //Set masterDJ status for current user to false
            [PFUser currentUser][@"masterDJ"] = [NSNumber numberWithBool:NO];
            [[PFUser currentUser] saveInBackground];

            [self newRoom];
        }

        //Alert for password for entering a room
    } else if (alertView.tag == 2) {
        if (buttonIndex == 0) {
            return;
        } else {
            //Finds room and checks if password matches to the one saved on Parse
            PFQuery *query = [PFQuery queryWithClassName:@"Room"];
            [query whereKey:@"roomName" equalTo:self.roomToEnterName];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *room, NSError *error) {
                if ([[alertView textFieldAtIndex:0].text isEqualToString:room[@"password"]]) {
                    //If password correct, add user as listener, present voting view
                    [room addUniqueObject:[PFUser currentUser] forKey:@"listeners"];
                    [room saveInBackground];

                    // display song header view controller (not voting view)
                    CGSongHeaderViewController *shvc = [[CGSongHeaderViewController alloc] init];
                    shvc.roomOwner = room;
                    [self.navigationController pushViewController:shvc animated:YES];
                } else {
                    //Show wrong password alert
                    UIAlertView *wrongPasswordAlert = [[UIAlertView alloc] initWithTitle:@"Wrong password!" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [wrongPasswordAlert show];
                }
            }];
        }
    }

}

#pragma mark - Search

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    // register the nib so you can call cell dequeue
    [tableView registerNib:[UINib nibWithNibName:@"CGRoomCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"CGRoomCell"];
}

// when a user searches, then filterContentForSearchText is called
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];

    // change background image when searching
    UIImage *patternImage = [UIImage imageNamed:self.backgroundName];
    [controller.searchResultsTableView setBackgroundColor:[UIColor colorWithPatternImage: patternImage]];
    controller.searchResultsTableView.bounces=FALSE;
    controller.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    return YES;
}

// query all the rooms and return the results
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[c] %@) OR (masterDJName CONTAINS[c] %@)", searchText, searchText];
    self.searchResults = [_parseData filteredArrayUsingPredicate:resultPredicate];
}

#pragma mark State Restoration
//+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
//{
//    return [[self alloc] init];
//}

@end
