//
//  CGRoomDetailViewController.h
//  ToBeDJ
//
//  Created by Kimberley Yu on 7/14/14.
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface CGRoomDetailViewController : UIViewController

@property (nonatomic, assign) PFObject *currentRoom;
@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, copy) void (^cancelBlock)(void);

- (instancetype) initForNewRoom:(BOOL)isNew;

@end
