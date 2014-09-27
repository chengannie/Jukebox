//
//  CGVotingViewController.h
//  ToBeDJ
//
//  Created by Yian Cheng on 7/14/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface CGVotingViewController : UIViewController

@property (strong, nonatomic) PFObject *roomOwner;

- (IBAction)downVote:(id)sender;
- (IBAction)upVote:(id)sender;

@end
