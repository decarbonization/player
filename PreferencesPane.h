//
//  PreferencesPane.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesPane : NSViewController

#pragma mark Properties

///The name of the pane.
@property (nonatomic, readonly, copy) NSString *name;

///The icon of the pane.
@property (nonatomic, readonly, copy) NSImage *icon;

#pragma mark - Adding/Removing

- (void)paneWillBeRemovedFromWindow:(NSWindow *)window;

- (void)paneWasAddedToWindow:(NSWindow *)window;

@end
