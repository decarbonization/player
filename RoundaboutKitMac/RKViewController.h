//
//  RKViewController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RKNavigationController, RKNavigationItem;

///The RKViewController class adds several features to NSViewController that
///bring it closer in line with the feature set of UIViewController.
///
///The RKNavigationController stack uses RKViewControllers.
@interface RKViewController : NSViewController

///Initialize the receiver to represent a given view.
- (id)initWithView:(NSView *)view;

///Return the receiver’s nib bundle if it exists.
- (NSBundle *)nibBundle;

///Return the name of the receiver’s nib file, if one was specified.
- (NSString *)nibName;

#pragma mark - Loading

///Invoked when the view is about to load.
///
///Subclasses do not need to invoke super.
- (void)viewWillLoad;

///Invoked when the view has loaded.
///
///Subclasses do not need to invoke super.
- (void)viewDidLoad;

#pragma mark - Appearance

///Notifies the view controller that its view is about to be added to a view hierarchy.
- (void)viewWillAppear:(BOOL)animated;

///Notifies the view controller that its view was added to a view hierarchy.
- (void)viewDidAppear:(BOOL)animated;

///Notifies the view controller that its view is about to be removed from the view hierarchy.
- (void)viewWillDisappear:(BOOL)animated;

///Notifies the view controller that its view was removed from the view hierarchy.
- (void)viewDidDisappear:(BOOL)animated;

#pragma mark - Properties

///Whether or not the view controller's view is loaded.
@property (nonatomic, readonly) BOOL isViewLoaded;

#pragma mark - Navigation Stack Support

///The navigation controller that contains this view controller.
///
///This property will automatically be set when the view controller
///is placed within a navigation controller.
@property (nonatomic, readonly, unsafe_unretained) RKNavigationController *navigationController;

///The navigation item of the view controller.
///
///The default implementation of this property provides a factory navigation item.
@property (nonatomic, readonly) RKNavigationItem *navigationItem;

#pragma mark - Containing View Controllers

///The parent view controller of the recipient.
@property (nonatomic, readonly) RKViewController *parentViewController;

///Called just before the view controller is added or removed from a container view controller.
- (void)willMoveToParentViewController:(RKViewController *)parent;

///Called after the view controller is added or removed from a container view controller.
- (void)didMoveToParentViewController:(RKViewController *)parent;

#pragma mark -

///An array of the view controllers that are the children of the receiver in the view controller hierarchy.
@property (nonatomic, readonly) NSArray *childViewControllers;

///Adds the given view controller as a child.
- (void)addChildViewController:(RKViewController *)childController;

///Removes the receiver from its parent in the view controller hierarchy.
- (void)removeFromParentViewController;

#pragma mark - Actions

///Causes the receiver to pop itself from its containing navigation controller.
///
///This method does nothing if the receiver's `.navigationController` is not set.
- (IBAction)popFromNavigationController:(id)sender;

@end
