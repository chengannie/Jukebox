//
//  CGLoginViewController.m
//  ToBeDJ
//
//  Created by Joyce Yan on 7/11/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGLoginViewController.h"

#import <Parse/Parse.h>
#import "CGMusicViewController.h"
#import "CGRoomTableViewController.h"

@interface CGLoginViewController ()

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UILabel *jukeboxLabel;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *facebookIcon;
@property (weak, nonatomic) IBOutlet UIView *separatorLine;

@end

@implementation CGLoginViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {

    // initialize the view
    [super viewDidLoad];

    // setup the navigation controller
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    // set the background
    [self.view addSubview:self.backgroundImage];
    [self.view sendSubviewToBack:self.backgroundImage];

    // set up the jukebox label
    self.jukeboxLabel.font = [UIFont fontWithName:@"GrandHotel-Regular" size:72];

    // set up the login "button"
    self.loginLabel.font = [UIFont fontWithName:@"Avenir" size:18];
    self.loginLabel.textColor = [UIColor whiteColor];
    self.buttonView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.buttonView.layer.borderWidth = 2.0f;
    self.buttonView.layer.cornerRadius = 5;
    self.buttonView.layer.masksToBounds = YES;
    [self.view bringSubviewToFront:self.loginButton];

    // disable back button
    self.navigationItem.hidesBackButton = YES;
}

#pragma mark - Login methods

- (IBAction)loginButtonTouchHandler:(id)sender
{
    // make the button translucent when you touch it
    UIColor *touchedButtonColor = [UIColor colorWithWhite:1 alpha:0.5];
    self.buttonView.layer.borderColor = touchedButtonColor.CGColor;
    self.loginLabel.textColor = touchedButtonColor;
    [self.separatorLine setBackgroundColor:touchedButtonColor];
    [self.facebookIcon setAlpha:0.5];

    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[@"public_profile"];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {

            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Uh oh. The user cancelled the Facebook login." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        } else if (user.isNew) {
            user[@"masterDJ"] = [NSNumber numberWithBool:NO];
            [user saveInBackground];
            [self.navigationController popToRootViewControllerAnimated:NO];
        } else {
            [self.navigationController popToRootViewControllerAnimated:NO];
        }
        
    }];
    
    [_activityIndicator startAnimating]; // Show loading indicator until login is finished
}


@end
