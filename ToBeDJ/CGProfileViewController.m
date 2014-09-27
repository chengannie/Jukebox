//
//  CGProfileViewController.m
//  ToBeDJ
//
//  Created by Joyce Yan on 7/23/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGProfileViewController.h"

#import <Parse/Parse.h>
#import "SWRevealViewController.h"
#import "CGEditViewController.h"

@interface CGProfileViewController () <UIViewControllerRestoration>

// UITableView header view properties
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UIImageView *profilePicture;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITableView *favoritesTable;

@property (nonatomic, strong) NSMutableData *imageData;
@property(nonatomic, strong) NSArray *favorites;
@property (nonatomic, strong) NSString *nameFont;
@property (nonatomic, strong) NSString *backgroundName;
@property (weak, nonatomic) IBOutlet UILabel *favoritesLabel;

@end

@implementation CGProfileViewController

#pragma mark Initializers

// the designated initializer
- (instancetype) init
{
    self = [super init];
    if (self) {
        self.nameFont = @"Avenir";
        self.backgroundName = @"background.jpg";
        
        // state restoration
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

#pragma mark View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.favoritesLabel.font = [UIFont fontWithName:self.nameFont size:20];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
    
    UILabel *navigationBarTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    navigationBarTitleLabel.backgroundColor = [UIColor clearColor];
    navigationBarTitleLabel.textAlignment = NSTextAlignmentCenter;
    navigationBarTitleLabel.textColor = [UIColor whiteColor];
    navigationBarTitleLabel.text = @"DJ Profile";
    navigationBarTitleLabel.font = [UIFont fontWithName:self.nameFont size:18];
    [navigationBarTitleLabel sizeToFit];
    self.navigationItem.titleView = navigationBarTitleLabel;
    
    self.favoritesTable.dataSource = self;
    self.favoritesTable.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateProfile];
}

- (void)viewDidLoad
{
    self.favorites = [PFUser currentUser][@"likes"];
    // basic setup
    [super viewDidLoad];
    self.favoritesTable.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];

    // enable multi-line label
    self.descriptionLabel.numberOfLines = 0;
    [self.descriptionLabel sizeToFit];

    // set up the slide menu
    SWRevealViewController *revealController = [self revealViewController];
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];

    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc]
                                         initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                         style:UIBarButtonItemStyleBordered
                                         target:revealController
                                         action:@selector(revealToggle:)];

    self.navigationItem.leftBarButtonItem = revealButtonItem;

    // set up the edit button
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                 target:self
                                                                                 action:@selector(editButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightButton;

    // get any cached values before we retrieve the latest from facebook
    if ([PFUser currentUser]) {
        [self updateProfile];
    }

    // send the facebook request
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

            // update the views accordingly
            [self updateProfile];
        }
    }];
}

#pragma mark Profile Picture Upload

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // As chuncks of the image are received, we build our data file
    [self.imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // All data has been downloaded, now we can set the image in the header image view
    self.profilePicture.image = [UIImage imageWithData:self.imageData];

    // Add a nice corner radius to the image
    self.profilePicture.layer.cornerRadius = 8.0f;
    self.profilePicture.layer.masksToBounds = YES;
}

#pragma mark Buttons Clicked

- (void)editButtonPressed:(id)sender
{
    [self.navigationController pushViewController:[[CGEditViewController alloc] init] animated:YES];
}

- (void)logoutButtonTouchHandler:(id)sender
{
    // Logout user, this automatically clears the cache
    [PFUser logOut];

    // Return to login view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark Update Profile

- (void)updateProfile
{
    // Set the name in the header view label
    if ([[PFUser currentUser] objectForKey:@"profile"][@"name"]) {
        self.nameLabel.text = [[PFUser currentUser] objectForKey:@"profile"][@"name"];
        self.nameLabel.font = [UIFont fontWithName:self.nameFont size:20];
    }

    // Download the user's facebook profile picture
    self.imageData = [[NSMutableData alloc] init]; // the data will be loaded in here

    if ([[PFUser currentUser] objectForKey:@"profile"][@"pictureURL"]) {
        NSURL *pictureURL = [NSURL URLWithString:[[PFUser currentUser] objectForKey:@"profile"][@"pictureURL"]];

        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                              timeoutInterval:2.0f];
        // Run network request asynchronously
        NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        if (!urlConnection) {
            NSLog(@"Failed to download picture");
        }
    }

    // load the user's description
    PFUser *user = [PFUser currentUser];
    if (user[@"description"]) {
        self.descriptionLabel.text = user[@"description"];
        self.descriptionLabel.font = [UIFont fontWithName:self.nameFont size:16];
    } else {
        self.descriptionLabel.text = NSLocalizedString(@"(no description yet)", nil);
    }
}

#pragma mark Favorites Table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.favorites count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    cell.textLabel.text= self.favorites[indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:self.nameFont size:16];
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView = [UIView new];
    cell.selectedBackgroundView = [UIView new];
    
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark State Restoration
+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

@end
