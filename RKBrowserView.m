//
//  RKBrowserView.m
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 1/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserView.h"
#import "RKBrowserViewPrivate.h"

#import "RKAnimator.h"

#import "RKBrowserLevel.h"
#import "RKBrowserLevelInternal.h"

#import "RKBrowserTableView.h"
#import "RKBrowserLevelController.h"

@implementation RKBrowserView

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect]))
	{
		
	}
	
	return self;
}

@synthesize delegate = mDelegate;

#pragma mark -

- (void)viewDidMoveToWindow
{
	[[self window] setAcceptsMouseMovedEvents:YES];
	
	if(mHoverTrackingArea)
	{
		[self removeTrackingArea:mHoverTrackingArea];
		mHoverTrackingArea = nil;
	}
	
	if([self window])
	{
		mHoverTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
														  options:(NSTrackingAssumeInside | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect) 
															owner:self 
														 userInfo:nil];
		
		[self addTrackingArea:mHoverTrackingArea];
	}
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	if([item action] == @selector(goBack:))
	{
		return [self canGoBack];
	}
	else if([item action] == @selector(goForward:))
	{
		return [self canGoForward];
	}
	
	return YES;
}

#pragma mark - Levels

///Returns the browser level behind the one currently
///being displayed in the browser, if applicable.
- (RKBrowserLevel *)previousBrowserLevel
{
	RKBrowserLevel *previousBrowserLevel = self.browserLevel.cachedPreviousLevel;
	if(previousBrowserLevel.isValid)
		return previousBrowserLevel;
	
	return nil;
}

///Returns the browser level in front of the one currently
///being displayed in the browser, if applicable.
- (RKBrowserLevel *)nextBrowserLevel
{
	RKBrowserLevel *cachedNextLevel = self.browserLevel.cachedNextLevel;
	if(cachedNextLevel.isValid)
		return cachedNextLevel;
	
	return nil;
}

#pragma mark - Controllers

///Return the controller for a specified browser level, creating and caching it if it doesn't exist.
- (RKBrowserLevelController *)controllerForBrowserLevel:(RKBrowserLevel *)level
{
	NSParameterAssert(level);
	
	RKBrowserLevelController *controller = level.controller;
	if(controller)
		return controller;
	
	controller = [[RKBrowserLevelController alloc] initWithBrowserLevel:level browserView:self];
	level.controller = controller;
	
	return controller;
}

///Forget the controller for a browser level.
- (void)forgetControllerForBrowserLevel:(RKBrowserLevel *)level
{
	NSParameterAssert(level);
	
	level.controller = nil;
}

#pragma mark -

///Returns the browser level controller behind the one
///currently being displayed in the browser, if applicable.
- (RKBrowserLevelController *)previousBrowserLevelController
{
	RKBrowserLevel *previousLevel = [self previousBrowserLevel];
	if(previousLevel && previousLevel.isValid)
		return [self controllerForBrowserLevel:previousLevel];
	
	return nil;
}

///Returns the browser level controller in front of the one
///currently being displayed in the browser, if applicable.
- (RKBrowserLevelController *)nextBrowserLevelController
{
	RKBrowserLevel *nextLevel = [self nextBrowserLevel];
	if(nextLevel && nextLevel.isValid)
		return [self controllerForBrowserLevel:nextLevel];
	
	return nil;
}

#pragma mark - Showing levels

- (void)showLevelControllerWithoutTransition:(RKBrowserLevelController *)controller
{
	NSParameterAssert(controller);
	
	NSView *levelView = [controller view];
	
	NSRect newLevelViewFrame = NSZeroRect;
	newLevelViewFrame.origin = NSZeroPoint;
	newLevelViewFrame.size = [self frame].size;
	
	[levelView setFrame:newLevelViewFrame];
	[levelView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	
	[controller controllerWillBecomeVisibleInBrowser:self];
	[self addSubview:levelView];
	[controller controllerDidBecomeVisibleInBrowser:self];
	
	[mVisibleBrowserLevelController controllerWillBeRemovedFromBrowser:self];
	[[mVisibleBrowserLevelController view] removeFromSuperviewWithoutNeedingDisplay];
	[mVisibleBrowserLevelController controllerWasRemovedFromBrowser:self];
	
	mVisibleBrowserLevelController = controller;
	
	[[self window] makeFirstResponder:controller.tableView];
}

- (void)transitionForwardToController:(RKBrowserLevelController *)controller
{
	NSParameterAssert(controller);
	
	if(!mVisibleBrowserLevelController)
	{
		[self showLevelControllerWithoutTransition:controller];
		return;
	}
	
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        NSView *levelView = [controller view];
		
		NSRect newLevelViewFrame = NSZeroRect;
		newLevelViewFrame.size = [self frame].size;
		newLevelViewFrame.origin = NSMakePoint(NSWidth(newLevelViewFrame), 0.0);
		
		[levelView setFrame:newLevelViewFrame];
		[levelView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		
		[controller controllerWillBecomeVisibleInBrowser:self];
		[self addSubview:levelView];
		[controller controllerDidBecomeVisibleInBrowser:self];
		
		newLevelViewFrame.origin = NSZeroPoint;
		[transaction setFrame:newLevelViewFrame forTarget:levelView];
		
		NSRect oldLevelViewFrame = newLevelViewFrame;
		oldLevelViewFrame.origin = NSMakePoint(-NSWidth(newLevelViewFrame), 0.0);
		[transaction setFrame:oldLevelViewFrame forTarget:[mVisibleBrowserLevelController view]];
    } completionHandler:^(BOOL didFinish) {
		[mVisibleBrowserLevelController controllerWillBeRemovedFromBrowser:self];
		[[mVisibleBrowserLevelController view] removeFromSuperviewWithoutNeedingDisplay];
		[mVisibleBrowserLevelController controllerWasRemovedFromBrowser:self];
		
		mVisibleBrowserLevelController = controller;
		
		[[self window] makeFirstResponder:controller.tableView];
	}];
}

- (void)transitionBackwardToController:(RKBrowserLevelController *)controller
{
	NSParameterAssert(controller);
	
	if(!mVisibleBrowserLevelController)
	{
		[self showLevelControllerWithoutTransition:controller];
		return;
	}
	
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        NSView *levelView = [controller view];
		
		NSRect newLevelViewFrame = NSZeroRect;
		newLevelViewFrame.size = [self frame].size;
		newLevelViewFrame.origin = NSMakePoint(-NSWidth(newLevelViewFrame), 0.0);
		
		[levelView setFrame:newLevelViewFrame];
		[levelView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		
		[controller controllerWillBecomeVisibleInBrowser:self];
		[self addSubview:levelView];
		[controller controllerDidBecomeVisibleInBrowser:self];
		
		newLevelViewFrame.origin = NSZeroPoint;
		[transaction setFrame:newLevelViewFrame forTarget:levelView];
		
		NSRect oldLevelViewFrame = newLevelViewFrame;
		oldLevelViewFrame.origin = NSMakePoint(NSWidth(newLevelViewFrame), 0.0);
		[transaction setFrame:oldLevelViewFrame forTarget:[mVisibleBrowserLevelController view]];
    } completionHandler:^(BOOL didFinish) {
		[mVisibleBrowserLevelController controllerWillBeRemovedFromBrowser:self];
		[[mVisibleBrowserLevelController view] removeFromSuperviewWithoutNeedingDisplay];
		[mVisibleBrowserLevelController controllerWasRemovedFromBrowser:self];
		
		mVisibleBrowserLevelController = controller;
		
		[[self window] makeFirstResponder:controller.tableView];
	}];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:dirtyRect];
}

#pragma mark - Manipulating Levels

- (void)setBrowserLevel:(RKBrowserLevel *)visibleBrowserLevel
{
	[mDelegate browserView:self willMoveIntoLevel:visibleBrowserLevel fromLevel:mBrowserLevel];
	
	mBrowserLevel.parentBrowser = nil;
	mBrowserLevel.cachedNextLevel = nil;
	
	mBrowserLevel = [visibleBrowserLevel deepestCachedLevel];
	mBrowserLevel.parentBrowser = self;
	
	RKBrowserLevelController *controller = [self controllerForBrowserLevel:mBrowserLevel];
	[self showLevelControllerWithoutTransition:controller];
}

- (RKBrowserLevel *)browserLevel
{
	return mBrowserLevel;
}

#pragma mark -

- (void)moveIntoBrowserLevel:(RKBrowserLevel *)level
{
	NSParameterAssert(level);
	
	[mDelegate browserView:self willMoveIntoLevel:level fromLevel:mBrowserLevel];
	
	RKBrowserLevelController *controller = [self controllerForBrowserLevel:level];
	[self transitionForwardToController:controller];
	
	level.cachedPreviousLevel = mBrowserLevel;
	mBrowserLevel.cachedNextLevel = level;
	
	[self willChangeValueForKey:@"browserLevel"];
	mBrowserLevel.parentBrowser = nil;
	mBrowserLevel = level;
	mBrowserLevel.parentBrowser = self;
	[self didChangeValueForKey:@"browserLevel"];
}

- (void)leaveBrowserLevel
{
	RKBrowserLevel *newLevel = mBrowserLevel.cachedPreviousLevel;
	
	[mDelegate browserView:self willMoveIntoLevel:newLevel fromLevel:mBrowserLevel];
	
	if(!mBrowserLevel.cachedPreviousLevel)
	{
		[mVisibleBrowserLevelController controllerWillBeRemovedFromBrowser:self];
		[[mVisibleBrowserLevelController view] removeFromSuperviewWithoutNeedingDisplay];
		mVisibleBrowserLevelController = nil;
		[mVisibleBrowserLevelController controllerWasRemovedFromBrowser:self];
	}
	else
	{
		RKBrowserLevelController *controller = [self controllerForBrowserLevel:newLevel];
		[self transitionBackwardToController:controller];
	}
	
	[self forgetControllerForBrowserLevel:mBrowserLevel];
	
	[self willChangeValueForKey:@"browserLevel"];
	mBrowserLevel.parentBrowser = nil;
	mBrowserLevel = newLevel;
	mBrowserLevel.parentBrowser = self;
	[self didChangeValueForKey:@"browserLevel"];
}

#pragma mark - Actions

+ (NSSet *)keyPathsForValuesAffectingCanGoBack
{
	return [NSSet setWithObjects:@"browserLevel", nil];
}

- (BOOL)canGoBack
{
	return (self.browserLevel && [self previousBrowserLevel].isValid);
}

- (IBAction)goBack:(id)sender
{
	if(self.browserLevel && [self previousBrowserLevel].isValid)
		[self leaveBrowserLevel];
	else
		NSBeep();
}

+ (NSSet *)keyPathsForValuesAffectingCanGoForward
{
	return [NSSet setWithObjects:@"browserLevel", nil];
}

- (BOOL)canGoForward
{
	return [self nextBrowserLevel].isValid;
}

- (IBAction)goForward:(id)sender
{
	RKBrowserLevel *nextLevel = [self nextBrowserLevel];
	if(nextLevel.isValid)
		[self moveIntoBrowserLevel:nextLevel];
	else
		NSBeep();
}

- (IBAction)goToRoot:(id)sender
{
	RKBrowserLevel *shallowestLevel = [self.browserLevel shallowestLevel];
	if(![shallowestLevel isEqualTo:self.browserLevel])
	{
		shallowestLevel.cachedNextLevel = nil;
		self.browserLevel = shallowestLevel;
	}
}

#pragma mark - Handling Keys

- (BOOL)handleSpecialKeyPress:(RKBrowserSpecialKey)key InSubordinateTableView:(NSTableView *)tableView
{
    if(key == kRKBrowserSpecialKeyDelete)
    {
        return [mBrowserLevel deleteItems:mVisibleBrowserLevelController.selectedItems];
    }
	else if(key == kRKBrowserSpecialKeyLeftArrow)
	{
		[self goBack:nil];
		
		return YES;
	}
	else if(key == kRKBrowserSpecialKeyRightArrow)
	{
		id selectedItem = [mVisibleBrowserLevelController.selectedItems lastObject];
		if(!selectedItem)
			return NO;
		
		if(RK_FLAG_IS_SET([NSEvent modifierFlags], NSShiftKeyMask))
		{
			[mBrowserLevel handleNonLeafSelectionForItem:selectedItem];
			
			return YES;
		}
		else
		{
			if([mBrowserLevel isChildLevelAvailableForItem:selectedItem])
			{
				RKBrowserLevel *nextLevel = [mBrowserLevel childBrowserLevelForItem:selectedItem];
				[self moveIntoBrowserLevel:nextLevel];
			}
			
			return YES;
		}
	}
	else if(key == kRKBrowserSpecialKeyEnter)
	{
		id selectedItem = [mVisibleBrowserLevelController.selectedItems lastObject];
		[mBrowserLevel handleNonLeafSelectionForItem:selectedItem];
		
		return YES;
	}
	
	return NO;
}

#pragma mark - Hover

- (void)mouseExited:(NSEvent *)event
{
	if(!mVisibleBrowserLevelController)
		return;
	
	RKBrowserTableView *targetTableView = mVisibleBrowserLevelController.tableView;
	targetTableView.hoveredUponRow = -1;
}

- (void)mouseMoved:(NSEvent *)event
{
	if(!mVisibleBrowserLevelController)
		return;
	
	NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
	RKBrowserTableView *targetTableView = mVisibleBrowserLevelController.tableView;
	NSPoint mouseLocationInTableView = [targetTableView convertPoint:mouseLocation fromView:self];
	
	targetTableView.hoveredUponRow = [targetTableView rowAtPoint:mouseLocationInTableView];
}

#pragma mark - Swiping

typedef enum {
	kSwipingToNothing = 0,
	kSwipingToNextLevel = 1,
	kSwipingToPreviousLevel = 2,
} SwipingDirection;

- (void)showTransitionalLevel:(RKBrowserLevel *)browserLevel forSwipe:(SwipingDirection)swipeDirection
{
	if(browserLevel)
	{
		RKBrowserLevelController *levelController = [self controllerForBrowserLevel:browserLevel];
		NSView *transitionalLevelView = [levelController view];
		
		NSRect transitionalBrowserViewFrame = NSZeroRect;
		transitionalBrowserViewFrame.size = [self frame].size;
		if(swipeDirection == kSwipingToNextLevel)
			transitionalBrowserViewFrame.origin.x = NSWidth(transitionalBrowserViewFrame);
		else if(swipeDirection == kSwipingToPreviousLevel)
			transitionalBrowserViewFrame.origin.x = -NSWidth(transitionalBrowserViewFrame);
		
		[transitionalLevelView setFrame:transitionalBrowserViewFrame];
		
		[levelController controllerWillBecomeVisibleInBrowser:self];
		[self addSubview:transitionalLevelView positioned:NSWindowAbove relativeTo:[mVisibleBrowserLevelController view]];
		[levelController controllerDidBecomeVisibleInBrowser:self];
	}
}

#pragma mark -

///This event is propagated to us by our child table views.
- (void)scrollWheel:(NSEvent *)event
{
	if(![[RKAnimator animator] isAnimating:[mVisibleBrowserLevelController view]] || mIsSwipe)
	{
		return;
	}
	
	if([event scrollingDeltaY] == 0.0 && 
	   [NSEvent isSwipeTrackingFromScrollEventsEnabled] &&
	   [event phase] == NSEventPhaseChanged)
	{
		BOOL swipingBackwards = ([event scrollingDeltaX] > 0.0);
		
		SwipingDirection swipeMode = kSwipingToNothing;
		if(swipingBackwards && mBrowserLevel.cachedPreviousLevel.isValid)
			swipeMode = kSwipingToPreviousLevel;
		else if(!swipingBackwards && mBrowserLevel.cachedNextLevel.isValid)
			swipeMode = kSwipingToNextLevel;
		
		CGFloat minThreshold = swipingBackwards? 0.0 : -1.0;
		CGFloat maxThreshold = swipingBackwards? 1.0 : 0.0;
		
		RKBrowserLevel *transitionalLevel = nil;
		NSView *transitionalView = nil;
		
		if(swipeMode == kSwipingToNothing)
		{
			minThreshold = 0.0;
			maxThreshold = 0.0;
		}
		else
		{
			if(swipeMode == kSwipingToPreviousLevel)
				transitionalLevel = [self previousBrowserLevel];
			else if(swipeMode == kSwipingToNextLevel)
				transitionalLevel = [self nextBrowserLevel];
			
			transitionalView = [[self controllerForBrowserLevel:transitionalLevel] view];
			
			[self showTransitionalLevel:transitionalLevel forSwipe:swipeMode];
		}
		
		mIsSwipe = YES;
		
		[event trackSwipeEventWithOptions:NSEventSwipeTrackingClampGestureAmount dampenAmountThresholdMin:minThreshold max:maxThreshold usingHandler:^(CGFloat gestureAmount, NSEventPhase phase, BOOL isComplete, BOOL *stop) {
			
			switch (swipeMode)
			{
				case kSwipingToPreviousLevel:
				{
					NSRect newCurrentViewFrame = [[mVisibleBrowserLevelController view] frame];
					newCurrentViewFrame.origin.x = round(NSWidth([self frame]) * gestureAmount);
					
					NSRect newTransitonalViewFrame = [transitionalView frame];
					newTransitonalViewFrame.origin.x = NSMinX(newCurrentViewFrame) - NSWidth(newTransitonalViewFrame) - 1.0;
					
					[[mVisibleBrowserLevelController view] setFrame:newCurrentViewFrame];
					[transitionalView setFrame:newTransitonalViewFrame];
					
					if(isComplete)
					{
						mIsSwipe = NO;
						
						if(gestureAmount == 1.0)
						{
							[mVisibleBrowserLevelController controllerWillBeRemovedFromBrowser:self];
							[[mVisibleBrowserLevelController view] removeFromSuperviewWithoutNeedingDisplay];
							[mVisibleBrowserLevelController controllerWasRemovedFromBrowser:self];
							
							[mDelegate browserView:self willMoveIntoLevel:transitionalLevel fromLevel:mBrowserLevel];
							
							NSRect newTransitonalViewFrame = [transitionalView frame];
							newTransitonalViewFrame.origin.x += 1.0;
							[transitionalView setFrame:newTransitonalViewFrame];
							
							mVisibleBrowserLevelController = [self controllerForBrowserLevel:transitionalLevel];
							
							[[self window] makeFirstResponder:mVisibleBrowserLevelController.tableView];
							
							[self willChangeValueForKey:@"browserLevel"];
							mBrowserLevel.parentBrowser = nil;
							mBrowserLevel = transitionalLevel;
							mBrowserLevel.parentBrowser = self;
							[self didChangeValueForKey:@"browserLevel"];
						}
						else
						{
							[transitionalView removeFromSuperviewWithoutNeedingDisplay];
						}
					}
					
					break;
				}
					
				case kSwipingToNextLevel:
				{
					NSRect newCurrentViewFrame = [[mVisibleBrowserLevelController view] frame];
					newCurrentViewFrame.origin.x = round(NSWidth([self frame]) * gestureAmount);
					
					NSRect newTransitonalViewFrame = [transitionalView frame];
					newTransitonalViewFrame.origin.x = NSMaxX(newCurrentViewFrame) + 1.0;
					
					[[mVisibleBrowserLevelController view] setFrame:newCurrentViewFrame];
					[transitionalView setFrame:newTransitonalViewFrame];
					
					if(isComplete)
					{
						mIsSwipe = NO;
						
						if(gestureAmount == -1.0)
						{
							[mVisibleBrowserLevelController controllerWillBeRemovedFromBrowser:self];
							[[mVisibleBrowserLevelController view] removeFromSuperviewWithoutNeedingDisplay];
							[mVisibleBrowserLevelController controllerWasRemovedFromBrowser:self];
							
							[mDelegate browserView:self willMoveIntoLevel:transitionalLevel fromLevel:mBrowserLevel];
							
							NSRect newTransitonalViewFrame = [transitionalView frame];
							newTransitonalViewFrame.origin.x -= 1.0;
							[transitionalView setFrame:newTransitonalViewFrame];
							
							mVisibleBrowserLevelController = [self controllerForBrowserLevel:transitionalLevel];
							
							[[self window] makeFirstResponder:mVisibleBrowserLevelController.tableView];
							
							[self willChangeValueForKey:@"browserLevel"];
							mBrowserLevel.parentBrowser = nil;
							mBrowserLevel = transitionalLevel;
							mBrowserLevel.parentBrowser = self;
							[self didChangeValueForKey:@"browserLevel"];
						}
						else
						{
							[transitionalView removeFromSuperviewWithoutNeedingDisplay];
						}
					}
					
					break;
				}
					
				case kSwipingToNothing:
				{
					if(isComplete)
					{
						mIsSwipe = NO;
					}
					
					NSRect newCurrentViewFrame = [[mVisibleBrowserLevelController view] frame];
					newCurrentViewFrame.origin.x = round(NSWidth([self frame]) * gestureAmount);
					
					[[mVisibleBrowserLevelController view] setFrame:newCurrentViewFrame];
					
					break;
				}
					
				default:
					break;
			}
		}];
	}
}

- (void)swipeWithEvent:(NSEvent *)event
{
	if([event deltaX] == 1.0 /* left */)
	{
		[self goForward:nil];
	}
	else if([event deltaX] == -1.0 /* right */)
	{
		[self goBack:nil];
	}
}

@end
