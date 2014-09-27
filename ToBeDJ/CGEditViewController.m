//
//  CGEditViewController.m
//  ToBeDJ
//
//  Created by Joyce Yan on 7/24/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import "CGEditViewController.h"

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "GCPlaceholderTextView.h"

@interface CGEditViewController () <UIViewControllerRestoration>

@property (nonatomic, strong) IBOutlet GCPlaceholderTextView *editDescriptionBox;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, strong) NSString *nameFont;
@property (nonatomic, strong) NSString *backgroundName;
@property (weak, nonatomic) IBOutlet UIView *saveButtonBorder;
@property (weak, nonatomic) IBOutlet GCPlaceholderTextView *descriptionTextField;

@end

@implementation CGEditViewController

// the designated initializer
- (instancetype)init
{
    self = [super init];
    if (self) {
        // state restoration
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        
        self.nameFont = @"Avenir";
        self.backgroundName = @"background.jpg";
    }
    return self;
}

#pragma mark View Lifecycle

- (void)viewDidLoad
{
    // basic initialization
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];

    // navigation bar UI
    UILabel *navigationBarTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    navigationBarTitleLabel.backgroundColor = [UIColor clearColor];
    navigationBarTitleLabel.textAlignment = NSTextAlignmentCenter;
    navigationBarTitleLabel.textColor = [UIColor whiteColor];
    navigationBarTitleLabel.text = @"Edit";
    navigationBarTitleLabel.font = [UIFont fontWithName:self.nameFont size:18];
    [navigationBarTitleLabel sizeToFit];
    self.navigationItem.titleView = navigationBarTitleLabel;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    // description UI
    self.descriptionLabel.font = [UIFont fontWithName:self.nameFont size:18];

    // save button UI
    self.saveButton.titleLabel.font = [UIFont fontWithName:self.nameFont size:16];
    self.saveButtonBorder.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveButtonBorder.layer.borderWidth = 2.0f;
    self.saveButtonBorder.layer.cornerRadius = 5;
    self.saveButtonBorder.layer.masksToBounds = YES;
    [self.view bringSubviewToFront:self.saveButton];

    // edit description box UI
    self.editDescriptionBox.placeholderColor = [UIColor whiteColor];
    self.editDescriptionBox.placeholder = NSLocalizedString(@"Enter description here.",);
    self.editDescriptionBox.layer.borderWidth = 2.0f;
    self.editDescriptionBox.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.editDescriptionBox.layer.cornerRadius = 5;
    self.editDescriptionBox.layer.masksToBounds = YES;
    self.editDescriptionBox.font = [UIFont fontWithName:self.nameFont size:16];
    self.editDescriptionBox.textColor = [UIColor whiteColor];
}

- (IBAction)saveButtonPressed:(id)sender
{
    // send us back to the DJ Profile view
    [self.navigationController popToRootViewControllerAnimated:YES];

    // store the written text into parse
    NSString *text = self.editDescriptionBox.text;
    PFUser *user = [PFUser currentUser];
    user[@"description"] = text;
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