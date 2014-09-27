//
//  CGRoomDetailViewController.m
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/14/14.
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import "CGRoomDetailViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import "CGAppDelegate.h"
#import "CGRoomTableViewController.h"
#import "CGMusicViewController.h"

@interface CGRoomDetailViewController () <UINavigationControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *roomNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *privacyOption;
- (IBAction)segmentedControlTapped:(id)sender;
@property (strong, nonatomic) NSString *nameFont;
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomPasswordBar;
@property (weak, nonatomic) IBOutlet UIView *topPasswordBar;
@property (weak, nonatomic) IBOutlet UIView *passwordLeftPadding;
@property (weak, nonatomic) IBOutlet UILabel *roomPrivacyLabel;
@property (nonatomic, strong) NSString *backgroundName;

- (IBAction)backgroundTapped:(id)sender;

@end

@implementation CGRoomDetailViewController

#pragma mark - Initializers

// the designated initializer
- (instancetype)initForNewRoom:(BOOL)isNew
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (isNew) {
            self.nameFont = @"Avenir";
            self.backgroundName = @"background.jpg";

            UIBarButtonItem *doneItem = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                         target:self
                                         action:@selector(save:)];
            self.navigationItem.rightBarButtonItem = doneItem;
            UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                           target:self
                                           action:@selector(cancel:)];
            self.navigationItem.leftBarButtonItem = cancelItem;
            
            UILabel *navigationBarTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            navigationBarTitleLabel.backgroundColor = [UIColor clearColor];
            navigationBarTitleLabel.textAlignment = NSTextAlignmentCenter;
            navigationBarTitleLabel.textColor = [UIColor whiteColor];
            navigationBarTitleLabel.text = @"New Room";
            navigationBarTitleLabel.font = [UIFont fontWithName:self.nameFont size:18];
            [navigationBarTitleLabel sizeToFit];
            self.navigationItem.titleView = navigationBarTitleLabel;
        }

        // register as observer
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(updateFonts)
                              name:UIContentSizeCategoryDidChangeNotification
                            object:nil];
        
        //Recognize when user taps background - used to dismiss keyboard
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [self.view addGestureRecognizer:gestureRecognizer];

        // initialize UI
        self.roomNameTextField.textColor = [UIColor whiteColor];
        CGRect frame = CGRectMake(20, 20, 180, 50);
        self.privacyOption.frame = frame;
        self.roomNameTextField.tintColor = [UIColor whiteColor];
        self.passTextField.tintColor = [UIColor whiteColor];
        self.passTextField.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
    }
    return self;
}

// another initializer
- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
{
    [NSException raise:@"Wrong initializer"
                format:@"Use initForNewRoom:"];
    return nil;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    self.roomNameLabel.textColor = [UIColor whiteColor];
    UIFont *mainFont = [UIFont fontWithName:self.nameFont size:16];
    self.roomNameLabel.font = mainFont;
    self.passwordLabel.font = mainFont;
    self.roomPrivacyLabel.font = mainFont;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    PFObject *room = self.currentRoom;
    self.roomNameTextField.text = room[@"roomName"];
    [self updateFonts];
    
    //Hide password fields and set switch to off as default
    _passTextField.hidden = YES;
    _bottomPasswordBar.hidden = YES;
    _topPasswordBar.hidden = YES;
    _passwordLabel.hidden = YES;
    _passwordLeftPadding.hidden = YES;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

#pragma mark - User Interface

- (void)save:(id)sender
{
//    // Data prep:
//    CGAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
//    CLLocationCoordinate2D currentCoordinate = appDelegate.currentLocation.coordinate;
//    PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentCoordinate.latitude longitude:currentCoordinate.longitude];
//    NSLog(@"%@", currentPoint);

    //Create and set properties of room object in Parse
    PFObject *room = self.currentRoom;
    room[@"roomName"] = self.roomNameTextField.text;
    room[@"masterDJ"] = [PFUser currentUser];
    room[@"nameDJ"] = [PFUser currentUser][@"profile"][@"name"];
    room[@"password"] = self.passTextField.text;
    room[@"readyToSkip"] = @NO;
    room[@"newSong"] = @NO;

//    room[@"location"] = currentPoint;
//    NSLog(@"%@", room);
//    NSLog(@"%@", room[@"location"]);

    // save the room asynchronously
    [room saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"couldn't save");
            NSLog(@"%@", error);
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alertView show];
            return;
        }
        if (succeeded) {
            NSLog(@"Successfully saved!");
            NSLog(@"%@", room);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[NSNotificationCenter defaultCenter] postNotificationName:roomCreatedNotification object:nil];
//            });
        } else {
            NSLog(@"Failed to save.");
        }
    }];

    // dismiss this view controller
    [self.presentingViewController dismissViewControllerAnimated:NO
                                                      completion:self.dismissBlock];
}

- (void)cancel:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:self.cancelBlock];
}

- (void)updateFonts
{
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.roomNameTextField.font = font;
    self.passTextField.font = font;
}


- (IBAction)segmentedControlTapped:(id)sender {
    PFObject *room = self.currentRoom;
    if (_privacyOption.selectedSegmentIndex == 0) {
        room[@"privacyLevel"] = @"Open";
        _passTextField.hidden = YES;
        _bottomPasswordBar.hidden = YES;
        _topPasswordBar.hidden = YES;
        _passwordLabel.hidden = YES;
        _passwordLeftPadding.hidden = YES;
    } else if (_privacyOption.selectedSegmentIndex == 1) {
        room[@"privacyLevel"] = @"Closed";
        _passTextField.hidden = NO;
        _bottomPasswordBar.hidden = NO;
        _topPasswordBar.hidden = NO;
        _passwordLabel.hidden = NO;
        _passwordLeftPadding.hidden = NO;
    }
}

- (void)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.textColor = [UIColor redColor];
    return YES;
}

#pragma mark - Dealloc

- (void)dealloc
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self];
}


//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    [textField resignFirstResponder];
//    return YES;
//}

@end
