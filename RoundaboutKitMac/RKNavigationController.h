//
//  RKNavigationController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKViewController.h"
#import "RKNavigationBar.h"

///The RKNavigationController class implements a specialized view controller that manages the navigation of hierarchical content.
@interface RKNavigationController : RKViewController
{
    NSMutableArray *_viewControllers;
    NSView *_visibleView;
    RKNavigationBar *_navigationBar;
}

///Initialize the receier with a given root view controller.
///
/// \param  viewController  The view controller that resides at the bottom of the navigation stack.
///
///This is the designated initializer.
- (id)initWithRootViewController:(RKViewController *)viewController;

#pragma mark - Stack

///The view controller at the root of the navigation stack.
@property (nonatomic, readonly) RKViewController *topViewController;

///The view controller that is currently visible to the user.
@property (nonatomic, readonly) RKViewController *visibleViewController;

///The view controllers on the stack.
@property (nonatomic, readonly, copy) NSArray *viewControllers;

#pragma mark - Navigation Bar

///The navigation bar associated with this navigation controller.
@property (nonatomic, readonly) RKNavigationBar *navigationBar;

///A Boolean value that determines whether the navigation bar is hidden.
@property(nonatomic, getter=isNavigationBarHidden) BOOL navigationBarHidden;

#pragma mark - Pushing and Popping Stack Items

///Pushes a view controller onto the receiver’s stack and updates the display.
- (void)pushViewController:(RKViewController *)viewController animated:(BOOL)animated;

///Pops the top view controller from the navigation stack and updates the display.
- (void)popViewControllerAnimated:(BOOL)animated;

///Pops view controllers until the specified view controller is at the top of the navigation stack.
- (void)popToViewController:(RKViewController *)viewController animated:(BOOL)animated;

///Pops all the view controllers on the stack except the root view controller and updates the display.
- (void)popToRootViewControllerAnimated:(BOOL)animated;

@end
