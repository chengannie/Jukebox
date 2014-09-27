//
//  CGAppDelegate.h
//  ToBeDJ
//
//  Created by Yian Cheng on 7/11/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class SWRevealViewController;

@interface CGAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SWRevealViewController *viewController;

@end