//
//  RKBrowserView.h
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 1/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum RKBrowserSpecialKey {
	kRKBrowserSpecialKeyDelete = 51,
	kRKBrowserSpecialKeyEnter = 36,
	kRKBrowserSpecialKeySpace = 49,
	kRKBrowserSpecialKeyLeftArrow = 123,
	kRKBrowserSpecialKeyRightArrow = 124,
};
typedef short RKBrowserSpecialKey;

@class RKBrowserLevel, RKBrowserLevelController;
@protocol RKBrowserViewDelegate;

///The RKBrowserView class provides a simple one-level-at-a-time iPhone style browser.
@interface RKBrowserView : NSView <NSUserInterfaceValidations>
{
	///The visible browser level.
	RKBrowserLevel *mBrowserLevel;
	
	///The currently visible browser level controller.
	RKBrowserLevelController *mVisibleBrowserLevelController;
	
	///Storage for `delegate`
	id <RKBrowserViewDelegate> mDelegate;
	
	///Whether or not a swipe is currently being executed.
	BOOL mIsSwipe;
	
	///The tracking area used to highlight rows.
	NSTrackingArea *mHoverTrackingArea;
}

#pragma mark Properties

///The visible level of the browser view.
///
///Changing the value of this property will cause the browser
///view to take on the hierarchy stored in the browser level.
@property (nonatomic) RKBrowserLevel *browserLevel;

///The delegate of the browser.
@property (nonatomic) IBOutlet id <RKBrowserViewDelegate> delegate;

#pragma mark - Manipulating Levels

///Adds a browser level at the top of the receiver's hierarchy.
- (void)moveIntoBrowserLevel:(RKBrowserLevel *)level;

///Exits from the receiver's top most browser level.
- (void)leaveBrowserLevel;

#pragma mark - Actions

///Whether or not the browser can go back. KVC compliant.
@property (nonatomic, readonly) BOOL canGoBack;

///Have the receiver go back a level, if possible.
- (IBAction)goBack:(id)sender;

#pragma mark -

///Whether or not the browser can go forward. KVC compliant.
@property (nonatomic, readonly) BOOL canGoForward;

///Have the receiver go forward a level, if possible.
- (IBAction)goForward:(id)sender;

#pragma mark -

///Have the receiver move to the top most level possible.
- (IBAction)goToRoot:(id)sender;

@end

///The delegate of `RKBrowserView`.
@protocol RKBrowserViewDelegate <NSObject>
@required

///Sent when the browser view is about to enter a new browser level.
- (void)browserView:(RKBrowserView *)browserView willMoveIntoLevel:(RKBrowserLevel *)newLevel fromLevel:(RKBrowserLevel *)oldLevel;

///Sent when a non-leaf item is double clicked in a browser level.
- (void)browserView:(RKBrowserView *)browserView nonLeafItem:(id)item wasDoubleClickedInLevel:(RKBrowserLevel *)level;

///Sent when a hover button is clicked on an item.
- (void)browserView:(RKBrowserView *)browserView hoverButtonForItem:(id)item wasClickedInLevel:(RKBrowserLevel *)level;

@end
