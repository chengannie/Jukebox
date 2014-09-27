//
//  CGSettingsViewController.m
//  ToBeDJ
//
//  Created by Joyce Yan on 7/24/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGSettingsViewController.h"

#import <Parse/Parse.h>
#import "SWRevealViewController.h"
#import "CGRoomTableViewController.h"
#import "CGAppDelegate.h"

@interface CGSettingsViewController ()

@property (nonatomic, strong) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UISlider *distanceSlider;
- (IBAction)sliderValueChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) NSString *nameFont;
@property (strong, nonatomic) NSString *backgroundName;

@end

@implementation CGSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.nameFont = @"Avenir";
        self.backgroundName = @"background.jpg";
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
    
    UILabel *navigationBarTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    navigationBarTitleLabel.backgroundColor = [UIColor clearColor];
    navigationBarTitleLabel.textAlignment = NSTextAlignmentCenter;
    navigationBarTitleLabel.textColor = [UIColor whiteColor];
    navigationBarTitleLabel.text = @"Settings";
    navigationBarTitleLabel.font = [UIFont fontWithName:self.nameFont size:18];
    [navigationBarTitleLabel sizeToFit];
    self.navigationItem.titleView = navigationBarTitleLabel;
    
    self.distanceSlider.minimumValue = 10.0;
    self.distanceSlider.maximumValue = 500.0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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
}

// event handler for when the logout button is pressed
- (IBAction)logoutButtonPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure you want to logout?"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Logout", nil];
    [alert show];
}

// alter actions based on what the user clicks in the alertview
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // do nothing if they hit "cancel"
        return;
    } else {
        // log out if they didn't
        [self logout];
    }
}

// what happens if the user chooses to actually log out
- (void)logout
{
    [PFUser logOut];
    SWRevealViewController *revealController = self.revealViewController;
    CGRoomTableViewController *roomTableView = [[CGRoomTableViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:roomTableView];
    [revealController pushFrontViewController:navigationController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sliderValueChanged:(id)sender
{
    // do nothing
}
@end
