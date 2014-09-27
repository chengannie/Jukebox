
/*

 Copyright (c) 2013 Joan Lluch <joan.lluch@sweetwilliamsl.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

 Original code:
 Copyright (c) 2011, Philip Kluz (Philip.Kluz@zuui.org)

 */

#import "CGMenuViewController.h"

#import "SWRevealViewController.h"
#import "CGRoomTableViewController.h"
#import "CGProfileViewController.h"
#import "CGSettingsViewController.h"

@interface CGMenuViewController() <UIViewControllerRestoration>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *nameFont;
@property (nonatomic, strong) NSString *backgroundName;

@end

@implementation CGMenuViewController : UIViewController

- (instancetype) init
{
    self = [super init];
    if (self) {

        // state restoration
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

    self.nameFont = @"Avenir";
    self.backgroundName = @"background.jpg";
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];

    UILabel *navigationBarTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    navigationBarTitleLabel.backgroundColor = [UIColor clearColor];
    navigationBarTitleLabel.textAlignment = NSTextAlignmentCenter;
    navigationBarTitleLabel.textColor = [UIColor whiteColor];
    navigationBarTitleLabel.text = @"Menu";
    navigationBarTitleLabel.font = [UIFont fontWithName:self.nameFont size:18];
    navigationBarTitleLabel.textAlignment = NSTextAlignmentCenter;
    [navigationBarTitleLabel sizeToFit];
    self.navigationItem.titleView = navigationBarTitleLabel;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:self.backgroundName] forBarMetrics:UIBarMetricsDefault];
}


#pragma mark - UITableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // insert a cell if there isn't already one
	static NSString *cellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSInteger row = indexPath.row;

	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
	}

    // set the background image
    cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:self.backgroundName]];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:self.nameFont size:16];

    // name the cells accordingly
	if (row == 0) {
		cell.textLabel.text = @"Home";
	} else if (row == 1) {
		cell.textLabel.text = @"Profile";
	} else if (row == 2) {
        cell.textLabel.text = @"Logout";
    }

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // pull out the cells and modify them
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:0.05f];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	// Grab a handle to the reveal controller, as if you'd do with a navigtion controller via self.navigationController.
    SWRevealViewController *revealController = self.revealViewController;

    // We know the frontViewController is a NavigationController
    UINavigationController *frontNavigationController = (id)revealController.frontViewController;  // <-- we know it is a NavigationController
    NSInteger row = indexPath.row;

	// the first row (=0) corresponds to the RoomTableView
	if (row == 0) {
		// Make sure we're not already in the RoomTableView
        if ( ![frontNavigationController.topViewController isKindOfClass:[CGRoomTableViewController class]] ) {
			//CGRoomTableViewController *roomTableViewController = [[CGRoomTableViewController alloc] init];
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.roomTableView];
			[revealController pushFrontViewController:navigationController animated:YES];
        } else {
            // Seems the user attempts to 'switch' to exactly the same controller he came from!
			[revealController revealToggle:self];
		}
	}

	// the second row (=1) corresponds to the ProfileViewController
	else if (row == 1) {
		// Make sure we're not already in the ProfileView
        if ( ![frontNavigationController.topViewController isKindOfClass:[CGProfileViewController class]] ) {
			CGProfileViewController *profileViewController = [[CGProfileViewController alloc] init];
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:profileViewController];
			[revealController pushFrontViewController:navigationController animated:YES];
        } else {
            // Seems the user attempts to 'switch' to exactly the same controller he came from!
			[revealController revealToggle:self];
		}
	}

    // the third row (=2) corresponds to calling the logout methods
    else if (row == 2) {
        [self logoutButtonPressed];
    }
}

#pragma mark - Logout

// event handler for when the logout button is pressed
- (void)logoutButtonPressed
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
        // take them back to the screen they were at earlier
        [self.revealViewController revealToggle:self];
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

#pragma mark State Restoration
+ (UIViewController*)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}
    
@end