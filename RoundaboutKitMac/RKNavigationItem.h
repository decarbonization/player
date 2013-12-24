//
//  RKNavigationItem.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKBarButton.h"

///The RKNavigationItem encapsulates information about a navigation item pushed onto an RKNavigationBar's stack.
///
///By default a navigation item has no left or right button and has a borderless NSTextField as its title view.
@interface RKNavigationItem : NSView

#pragma mark - Properties

///The title of the navigation item.
///
///This property does nothing if the title view is not an NSTextField instance (default).
@property (nonatomic, copy) NSString *title;

#pragma mark - Views

///The left button of the navigation item.
@property (nonatomic) NSView *leftView;

///The title view of the navigation item.
@property (nonatomic) NSView *titleView;

///The right button of the navigation item.
@property (nonatomic) NSView *rightView;

@end
