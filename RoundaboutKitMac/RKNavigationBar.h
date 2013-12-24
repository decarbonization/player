//
//  RKNavigationBar.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKNavigationItem.h"
#import "RKChromeView.h"

///The RKNavigationBar class implements a control for navigating hierarchical content.
@interface RKNavigationBar : RKChromeView

#pragma mark - Properties

///The navigation items of the bar.
@property (nonatomic, copy, readonly) NSArray *navigationItems;

///The item at the top of the navigation bar's stack.
@property (nonatomic, readonly) RKNavigationItem *topNavigationItem;

///The item currently visible to the user.
@property (nonatomic, readonly) RKNavigationItem *visibleNavigationItem;

#pragma mark - Pushing and Popping Items

///Pushes the given navigation item onto the receiver’s stack and updates the navigation bar.
- (void)pushNavigationItem:(RKNavigationItem *)navigationItem animated:(BOOL)animated;

///Pops the top item from the receiver’s stack and updates the navigation bar.
- (void)popNavigationItemAnimated:(BOOL)animated;

///Pops navigation items until the specified navigation item is at the top of the navigation stack.
- (void)popToNavigationItem:(RKNavigationItem *)navigationItem animated:(BOOL)animated;

///Pops all the navigation on the stack except the top most.
- (void)popToRootNavigationItemAnimated:(BOOL)animated;

@end
