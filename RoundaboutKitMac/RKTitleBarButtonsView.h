//
//  BKWindowTitleBarButtonsView.h
//  Pinna
//
//  Created by Peter MacWhinnie on 1/23/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The RKTitleBarButtonsView class is used to provide the titlebar (x|-|+) buttons for the RKBorderlessWindow class.
@interface RKTitleBarButtonsView : NSView
{
	NSWindow *mOldWindow;
	
	NSTrackingRectTag mTrackingArea;
	BOOL mIsRolloverActive;
	NSButton *mCloseButton;
	NSButton *mMinimizeButton;
	NSButton *mZoomButton;
}

///Returns the preferred size of the button view.
+ (NSSize)preferredSize;

///Returns the preferred frame of an instance of BKWindowTitleBarButtonsView.
+ (NSRect)preferredFrameInContentView:(NSView *)contentView;

@end
