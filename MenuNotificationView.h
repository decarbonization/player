//
//  BackgroundStatusView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 9/7/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CATextLayer;

@interface MenuNotificationView : NSView
{
	/** State **/
	
	///The status item responsible for displaying the view.
	NSStatusItem *mStatusItem;
	
	///The timer used to fade the status view out after 2 seconds.
	NSTimer *mFadeOutTimer;
	
	///Whether or not the status view is highlighted.
	BOOL mHighlighted;
	
	
	/** Properties **/
	
	///See `image`
	NSImage *mImage;
	
	///See `title`
	NSString *mTitle;
	
	///See `isPaused`
	BOOL mIsPaused;
	
	///See `action`
	dispatch_block_t mAction;
}

#pragma mark Initialization

///The designated initializer of BackgroundStatusView.
- (id)init;

#pragma mark - Properties

///The image of the background status view, if any.
@property (nonatomic, copy) NSImage *image;

///The title of the background status view.
@property (nonatomic, copy) NSString *title;

///Whether or not the receiver is paused.
@property (nonatomic) BOOL isPaused;

///The action to invoke when the background status view is clicked, if any.
@property (nonatomic, copy) dispatch_block_t action;

#pragma mark - Visibility

///Show the receiver where appropriate.
- (void)show;

///Close the receiver.
- (void)close;

@end
