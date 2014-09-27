//
//  CGSongCollectionViewController.h
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/21/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CGSongTableViewController : UITableViewController <UITableViewDelegate>

@property (strong, nonatomic) PFObject *roomOwner;

@end
