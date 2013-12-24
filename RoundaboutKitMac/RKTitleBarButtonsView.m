//
//  BKWindowTitleBarButtonsView.m
//  Pinna
//
//  Created by Peter MacWhinnie on 1/23/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "RKTitleBarButtonsView.h"
#import "NSObject+AssociatedValues.h"

enum {
	kWindowButtonWidth = 14,
	kWindowButtonHeight = 16,
	kWindowButtonInterButtonPadding = 7,
};

@implementation RKTitleBarButtonsView

#pragma mark Sizing

+ (NSSize)preferredSize
{
	return NSMakeSize((kWindowButtonWidth * 3) + (kWindowButtonInterButtonPadding * 2), kWindowButtonHeight);
}

+ (NSRect)preferredFrameInContentView:(NSView *)contentView
{
	NSParameterAssert(contentView);
	
	NSRect contentViewFrame = [contentView frame];
	
	NSRect preferredFrame;
	preferredFrame.size = [self preferredSize];
	preferredFrame.origin.x = 8.0;
	preferredFrame.origin.y = NSHeight(contentViewFrame) - NSHeight(preferredFrame) - 4.0;
	
	return preferredFrame;
}

#pragma mark - Destruction

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[mCloseButton unbind:@"image"];
	[mCloseButton unbind:@"alternateImage"];
	[mCloseButton unbind:@"enabled"];
	mCloseButton = nil;
	
	[mMinimizeButton unbind:@"image"];
	[mMinimizeButton unbind:@"alternateImage"];
	[mMinimizeButton unbind:@"enabled"];
	mMinimizeButton = nil;
	
	[mZoomButton unbind:@"image"];
	[mZoomButton unbind:@"alternateImage"];
	[mMinimizeButton unbind:@"enabled"];
	mZoomButton = nil;
}

#pragma mark - Initialization

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect]))
	{
		NSRect buttonFrame = NSMakeRect(0.0, 0.0, kWindowButtonWidth, kWindowButtonHeight);
		
        const NSUInteger windowStyleMask = (NSTitledWindowMask | 
                                            NSClosableWindowMask | 
                                            NSResizableWindowMask | 
                                            NSMiniaturizableWindowMask);
        
        mCloseButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:windowStyleMask];
		[mCloseButton setFrame:buttonFrame];
        [mCloseButton setAction:@selector(performClose:)];
		[self addSubview:mCloseButton];
		
		
		buttonFrame.origin.x += NSMaxX(buttonFrame) + kWindowButtonInterButtonPadding;
        mMinimizeButton = [NSWindow standardWindowButton:NSWindowMiniaturizeButton forStyleMask:windowStyleMask];
        [mMinimizeButton setFrame:buttonFrame];
		[mMinimizeButton setAction:@selector(performMiniaturize:)];
		[self addSubview:mMinimizeButton];
		
		
		buttonFrame.origin.x += NSMinX(buttonFrame);
        mZoomButton = [NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:windowStyleMask];
        [mZoomButton setFrame:buttonFrame];
		[mZoomButton setAction:@selector(performZoom:)];
		[self addSubview:mZoomButton];
	}
	
	return self;
}

#pragma mark - Notifications

- (void)windowDidResize:(NSNotification *)notification
{
	if(mTrackingArea)
	{
		[self removeTrackingRect:mTrackingArea];
		mTrackingArea = 0;
	}
	
	mTrackingArea = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
	
	mIsRolloverActive = NO;
}

- (void)viewDidMoveToWindow
{
	if(mTrackingArea)
	{
		[self removeTrackingRect:mTrackingArea];
		mTrackingArea = 0;
	}
	
	if(mOldWindow)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:mOldWindow];
		
		[mOldWindow removeObserver:self forKeyPath:@"isClosable"];
		[mOldWindow removeObserver:self forKeyPath:@"isMiniaturizable"];
		[mOldWindow removeObserver:self forKeyPath:@"isZoomable"];
	}
	
	NSWindow *window = [self window];
	if(window)
	{
		mTrackingArea = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:YES];
		
		[mCloseButton setTarget:window];
		[mCloseButton bind:@"enabled" toObject:window withKeyPath:@"isClosable" options:nil];
		
		[mMinimizeButton setTarget:window];
		[mMinimizeButton bind:@"enabled" toObject:window withKeyPath:@"isMiniaturizable" options:nil];
		
		[mZoomButton setTarget:window];
		[mZoomButton bind:@"enabled" toObject:window withKeyPath:@"isZoomable" options:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(windowDidResize:) 
													 name:NSWindowDidResizeNotification 
												   object:window];
		
		[window addObserver:self 
				 forKeyPath:@"isClosable" 
					options:0 
					context:NULL];
		[window addObserver:self 
				 forKeyPath:@"isMiniaturizable" 
					options:0 
					context:NULL];
		[window addObserver:self 
				 forKeyPath:@"isZoomable" 
					options:0 
					context:NULL];
	}
	else
	{
		[mCloseButton setTarget:nil];
		[mCloseButton unbind:@"enabled"];
		
		[mMinimizeButton setTarget:nil];
		[mMinimizeButton unbind:@"enabled"];
		
		[mZoomButton setTarget:nil];
		[mZoomButton unbind:@"enabled"];
	}
	
	mOldWindow = window;
}

#pragma mark - Behaviors

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

#pragma mark - Events

- (void)mouseExited:(NSEvent *)event
{
	mIsRolloverActive = NO;
    
    [mCloseButton setNeedsDisplay];
    [mMinimizeButton setNeedsDisplay];
    [mZoomButton setNeedsDisplay];
}

- (void)mouseEntered:(NSEvent *)event
{
    mIsRolloverActive = YES;
    
	[mCloseButton setNeedsDisplay];
    [mMinimizeButton setNeedsDisplay];
    [mZoomButton setNeedsDisplay];
}

///Must override this private method to provide a rollover state.
///Found on <http://www.cocoabuilder.com/archive/cocoa/280077-best-practices-for-using-standard-window-widgets-in-custom-window.html>
- (BOOL)_mouseInGroup:(NSButton *)widget
{
    return mIsRolloverActive;
}

@end
