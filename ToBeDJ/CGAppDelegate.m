//
//  CGAppDelegate.m
//  ToBeDJ
//
//  Created by Yian Cheng on 7/11/14.
//  Copyright (c) 2014 JAK. All rights reserved.
//

// NOTE: we are no longer using the files VotingViewController, SettingsViewController, and SongTableViewController
// also, state restoration implementation is not complete -- did not do anything after BNR pg 387, "Encoding Relevant Data"
// (stopped after I realized we were misunderstanding the purpose of state restoration)

#import "CGAppDelegate.h"

#import <Parse/Parse.h>
#import "SWRevealViewController.h"
#import "CGRoomTableViewController.h"
#import "CGMenuViewController.h"

@interface CGAppDelegate()<SWRevealViewControllerDelegate>
@end

@implementation CGAppDelegate

#pragma mark Application Lifetime

// added for state restoration
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // basic initialization
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    self.window.tintColor = [UIColor whiteColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // parse app setup
    [Parse setApplicationId:@"fOThyaj3LsoEHsDRBgPtSwKbYhgsh2zlvE22qdLE"
                  clientKey:@"chThCf2dLbyIxf0PzpYd52k04WADTtenQtEuTJSd"];
    [PFFacebookUtils initializeFacebook];

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // If state restoration did not occur, set up the view controller hierarchy
    // with the table view as the root view controller
    if (!self.window.rootViewController) {

        // set the front and rear navigation controllers
        CGRoomTableViewController *mainList = [[CGRoomTableViewController alloc] init];
        UINavigationController *frontNavigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:mainList];

        CGMenuViewController *rearList = [[CGMenuViewController alloc] init];
        rearList.roomTableView = mainList;
        UINavigationController *rearNavigationController = [[UINavigationController alloc]
                                                            initWithRootViewController:rearList];

        // set up the slide out menu bar
        SWRevealViewController *revealController = [[SWRevealViewController alloc]
                                                    initWithRearViewController:rearNavigationController
                                                           frontViewController:frontNavigationController];
        revealController.delegate = self;

        revealController.restorationIdentifier = NSStringFromClass([revealController class]);
        self.viewController = revealController;
        self.window.rootViewController = self.viewController;
    }

    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */

    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [[PFFacebookUtils session] close];
    [[MPMusicPlayerController iPodMusicPlayer] stop];
    
    // ADD SOMETHING TO DELETE ROOM OR SOMETHING....
}

#pragma mark Facebook Integration

// facebook login
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

#pragma mark State Restoration
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}


- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}

@end
