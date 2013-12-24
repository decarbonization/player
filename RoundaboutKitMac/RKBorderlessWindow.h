//
//  BKBorderlessWindow.h
//  Pinna
//
//  Created by Peter MacWhinnie on 11/25/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKKeyDispatcher.h"

@protocol RKBorderlessWindowDelegate;

///The BKBorderlessWindow class provides a window that has no chrome, but provides moving and resizing facilities.
///Note that a borderless window will only enable moving/resizing when the events in question originate on
///RKChromeViews, NSImageViews, or NSTextFields.
@interface RKBorderlessWindow : NSWindow
{
	/** Internal State **/
	NSUInteger mStyleMask;
	BOOL mIsAnimatingFrame;
	
	
	/** Resizing and Movement **/
	BOOL mShouldIgnoreMouseMovedEvents;
	BOOL mDragShouldResizeWindow;
	NSPoint mInitialDragLocation;
	NSPoint mInitialDragLocationOnScreen;
	NSRect mInitialWindowFrameForDrag;
	
	
	/** Zooming **/
	BOOL mWindowIsZoomed;
	NSString *mPrezoomFrameAutosaveName;
	NSColor *mPrezoomBackgroundColor;
	NSRect mPrezoomFrame;
	
	
	/** Properties **/
	BOOL mMaintainAspectRatioWhenResizing;
	BOOL mIsResizable;
	BOOL mIsMovable;
	BOOL mIsExcludedFromWindowsMenu;
	RKKeyDispatcher *mKeyListener;
	BOOL mCanBecomeKeyWindow, mCanBecomeMainWindow;
}

#pragma mark Properties

///Whether or not the window should maintain its aspect ratio when the user is resizing it.
@property (nonatomic) BOOL maintainAspectRatioWhenResizing;

///Whether or not the window is resizable. Separate from if it's zoomable.
@property (nonatomic) BOOL isResizable;

///Whether or not the window is movable. Default is YES.
@property (nonatomic) BOOL isMovable;

///The key listener of the window.
@property (nonatomic, retain) RKKeyDispatcher *keyListener;

@property (nonatomic) BOOL canBecomeKeyWindow, canBecomeMainWindow;

#pragma mark -

///ignore///
@property (nonatomic, assign) id <RKBorderlessWindowDelegate> delegate;

@end

@protocol RKBorderlessWindowDelegate <NSWindowDelegate>
@optional

///Sent when the user swipes over a portion of the window with their mouse input device.
- (BOOL)window:(NSWindow *)window wasSwipedWithEvent:(NSEvent *)event;

///Sent when the user rotates over a portion of the window with their mouse input device.
- (BOOL)window:(NSWindow *)window wasRotatedWithEvent:(NSEvent *)event;

///Sent when the user pinch-magnifies over a portion of the window with their mouse input device.
- (BOOL)window:(NSWindow *)window wasMagnifiedWithEvent:(NSEvent *)event;

@end

