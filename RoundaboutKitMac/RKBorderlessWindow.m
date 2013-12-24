//
//  BKBorderlessWindow.m
//  Pinna
//
//  Created by Peter MacWhinnie on 11/25/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "RKBorderlessWindow.h"
#import "RKMacPrelude.h"
#import "RKChromeView.h"

static const NSSize kBKBorderlessWindowResizerSize = { 20.0, 20.0 };

@implementation RKBorderlessWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)defer
{
	if((self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask
								  backing:bufferingType 
									defer:defer]))
	{
		[self setMovableByWindowBackground:YES];
		[self setOpaque:NO];
		[self setBackgroundColor:[NSColor clearColor]];
		
		mStyleMask = style;
		mIsResizable = ((mStyleMask & NSResizableWindowMask) == NSResizableWindowMask);
		mIsMovable = YES;
		
		mCanBecomeKeyWindow = YES;
		mCanBecomeMainWindow = YES;
		
		mIsExcludedFromWindowsMenu = YES;
	}
	
	return self;
}

- (void)awakeFromNib
{
	if([self frameAutosaveName])
		[self setFrameUsingName:[self frameAutosaveName] force:YES];
}

#pragma mark - Properties

@synthesize maintainAspectRatioWhenResizing = mMaintainAspectRatioWhenResizing;
@synthesize isResizable = mIsResizable;
@synthesize isMovable = mIsMovable;

- (void)setKeyListener:(RKKeyDispatcher *)keyListener
{
	mKeyListener = keyListener;
}

- (RKKeyDispatcher *)keyListener
{
	if(!mKeyListener)
		mKeyListener = [RKKeyDispatcher new];
	
	return mKeyListener;
}

#pragma mark - Overrides

@synthesize canBecomeKeyWindow = mCanBecomeKeyWindow, canBecomeMainWindow = mCanBecomeMainWindow;
@dynamic delegate;

#pragma mark -

- (BOOL)inLiveResize
{
	return mDragShouldResizeWindow;
}

#pragma mark -

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	if([item action] == @selector(performClose:))
	{
		if([[self delegate] respondsToSelector:@selector(windowShouldClose:)] &&
		   ![[self delegate] windowShouldClose:self])
		{
			return NO;
		}
		
		return ((mStyleMask & NSClosableWindowMask) == NSClosableWindowMask);
	}
	else if([item action] == @selector(performMiniaturize:))
	{
		return ((mStyleMask & NSMiniaturizableWindowMask) == NSMiniaturizableWindowMask);
	}
	else if([item action] == @selector(performZoom:))
	{
		return ((mStyleMask & NSResizableWindowMask) == NSResizableWindowMask);
	}
	
	return [super validateUserInterfaceItem:item];
}

#pragma mark - Closing/Zooming

- (BOOL)isClosable
{
	return ((mStyleMask & NSClosableWindowMask) == NSClosableWindowMask);
}

- (IBAction)performClose:(id)sender
{
	if(![self isClosable])
		return NSBeep();
	
	if([[self delegate] respondsToSelector:@selector(windowShouldClose:)] &&
	   ![[self delegate] windowShouldClose:self])
	{
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:self];
	
	if(mWindowIsZoomed)
		[self performZoom:sender];
	
	[self close];
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingIsMiniaturizable
{
	return [NSSet setWithObjects:@"isZoomed", nil];
}

- (BOOL)isMiniaturizable
{
	return !mWindowIsZoomed && ((mStyleMask & NSMiniaturizableWindowMask) == NSMiniaturizableWindowMask);
}

- (IBAction)performMiniaturize:(id)sender
{
	if(![self isMiniaturizable])
		return NSBeep();
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillMiniaturizeNotification object:self];
	
	if(mWindowIsZoomed)
		[self performZoom:sender];
	
	[self miniaturize:sender];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidMiniaturizeNotification object:self];
}

#pragma mark - Zooming

- (IBAction)performZoom:(id)sender
{
	if(![self isZoomable])
		return NSBeep();
	
	if(mWindowIsZoomed)
	{
		[self setBackgroundColor:mPrezoomBackgroundColor];
		[self setFrame:mPrezoomFrame display:YES animate:YES];
		if(mPrezoomFrameAutosaveName) [self setFrameAutosaveName:mPrezoomFrameAutosaveName];
		[self setHidesOnDeactivate:NO];
		
		[NSApp setPresentationOptions:NSApplicationPresentationDefault];
		
		[self willChangeValueForKey:@"isZoomed"];
		mWindowIsZoomed = NO;
		[self didChangeValueForKey:@"isZoomed"];
	}
	else
	{
		if((mStyleMask & NSResizableWindowMask) != NSResizableWindowMask)
			return;
		
		mPrezoomFrame = [self frame];
		mPrezoomFrameAutosaveName = [self frameAutosaveName];
		mPrezoomBackgroundColor = [self backgroundColor];
		
		[NSApp setPresentationOptions:NSApplicationPresentationAutoHideDock | NSApplicationPresentationAutoHideMenuBar];
		
		[self orderFront:nil];
		[self setFrameAutosaveName:@""];
		[self setFrame:(NSRect){NSZeroPoint, [[NSScreen mainScreen] frame].size} display:YES animate:YES];
		[self setBackgroundColor:[NSColor blackColor]];
		[self setHidesOnDeactivate:YES];
		
		[self willChangeValueForKey:@"isZoomed"];
		mWindowIsZoomed = YES;
		[self didChangeValueForKey:@"isZoomed"];
	}
	
	[self invalidateShadow];
}

- (BOOL)isZoomable
{
	return ((mStyleMask & NSResizableWindowMask) == NSResizableWindowMask);
}

- (void)setIsZoomed:(BOOL)flag
{
	if(flag != mWindowIsZoomed)
		[self performZoom:nil];
}

- (BOOL)isZoomed
{
	return mWindowIsZoomed;
}

#pragma mark - Windows Menu Support

- (void)orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber
{
	[super orderWindow:orderingMode relativeTo:otherWindowNumber];
	
	if(![self isExcludedFromWindowsMenu])
		[NSApp addWindowsItem:self title:[self title] filename:NO];
}

- (void)setTitle:(NSString *)title
{
	[super setTitle:title];
	
	if(![self isExcludedFromWindowsMenu] && [self isVisible])
		[NSApp changeWindowsItem:self title:title filename:NO];
}

- (void)close
{
	[super close];
	
	if(![self isExcludedFromWindowsMenu])
		[NSApp removeWindowsItem:self];
}

#pragma mark - Events

#pragma mark • Mouse

- (BOOL)isMovableByWindowBackground
{
	return NO;
}

- (void)mouseUp:(NSEvent *)event
{
	if(((mStyleMask & NSMiniaturizableWindowMask) == NSMiniaturizableWindowMask) && [event clickCount] >= 2)
		[self performMiniaturize:nil];
	
	//Save the window's frame.
	if([self frameAutosaveName])
		[self saveFrameUsingName:[self frameAutosaveName]];
	
	if(mDragShouldResizeWindow)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidEndLiveResizeNotification object:self];
		[[self contentView] setNeedsDisplay:YES];
	}
	
	//From <http://cs.oberlin.edu/~dadamson/DragonDrop/>
	if(mDragShouldResizeWindow && [self respondsToSelector:@selector(_endLiveResize)])
		[self performSelector:@selector(_endLiveResize)];
	
	mDragShouldResizeWindow = NO;
	mShouldIgnoreMouseMovedEvents = NO;
}

//From <http://www.cocoadev.com/index.pl?BKBorderlessWindow>
- (void)mouseDragged:(NSEvent *)event
{
	if(![NSApp isActive] || mShouldIgnoreMouseMovedEvents)
		return;
	
	NSRect windowFrame = [self frame];
	NSPoint currentLocationOnScreen = [self convertRectToScreen:(NSRect){[self mouseLocationOutsideOfEventStream], [self frame].size}].origin;
	NSPoint currentLocation = [event locationInWindow];
	
	if(mDragShouldResizeWindow && mIsResizable && !mWindowIsZoomed)
	{
		NSSize minimumSize = [self minSize];
		
		windowFrame.size.width = mInitialWindowFrameForDrag.size.width + (currentLocation.x - mInitialDragLocation.x);
		if(windowFrame.size.width < minimumSize.width)
			windowFrame.size.width = minimumSize.width;
		
		CGFloat heightDelta = (currentLocationOnScreen.y - mInitialDragLocationOnScreen.y);
		
		if((mInitialWindowFrameForDrag.size.height - heightDelta) < minimumSize.height)
		{
			windowFrame.size.height = minimumSize.height;
			windowFrame.origin.y = mInitialWindowFrameForDrag.origin.y + (mInitialWindowFrameForDrag.size.height - minimumSize.height);
		}
		else
		{
			windowFrame.size.height = (mInitialWindowFrameForDrag.size.height - heightDelta);
			windowFrame.origin.y = (mInitialWindowFrameForDrag.origin.y + heightDelta);
		}
		
		if([[self delegate] respondsToSelector:@selector(windowWillResize:toSize:)])
		{
			NSSize newSize = [[self delegate] windowWillResize:self toSize:windowFrame.size];
			windowFrame.origin.y -= newSize.height - windowFrame.size.height;
			windowFrame.origin.x -= newSize.width - windowFrame.size.width;
			windowFrame.size = newSize;
		}
		
		if(mMaintainAspectRatioWhenResizing && (minimumSize.height > 0.0 && minimumSize.width > 0.0))
		{
			CGFloat newHeight = windowFrame.size.width * minimumSize.height / minimumSize.width;
			windowFrame.origin.y -= newHeight - NSHeight(windowFrame);
			windowFrame.size.height = newHeight;
		}
		
		[self setFrame:windowFrame display:YES animate:NO];
	}
    else if(!mWindowIsZoomed && [self isMovable])
	{
		NSPoint newOrigin = NSMakePoint(currentLocationOnScreen.x - mInitialDragLocation.x, 
										currentLocationOnScreen.y - mInitialDragLocation.y);
		
		NSRect visibleScreenFrame = [[NSScreen mainScreen] visibleFrame];
		if(newOrigin.y + NSHeight(windowFrame) > NSMaxY(visibleScreenFrame))
			newOrigin.y = NSMaxY(visibleScreenFrame) - NSHeight(windowFrame);
		
		[self setFrameOrigin:newOrigin];
	}
}

- (void)mouseDown:(NSEvent *)event
{
	if(mIsAnimatingFrame)
	{
		mShouldIgnoreMouseMovedEvents = YES;
		return;
	}
	
	NSView *targetView = [[self contentView] hitTest:[event locationInWindow]];
	if(![targetView isKindOfClass:[RKChromeView class]] &&
	   ![targetView isKindOfClass:[NSTextField class]] &&
	   ![targetView isKindOfClass:[NSImageView class]] &&
	   [targetView class] != [NSView class] &&
	   ![targetView mouseDownCanMoveWindow])
	{
		mShouldIgnoreMouseMovedEvents = YES;
		return;
	}
	else
	{
		mShouldIgnoreMouseMovedEvents = ![targetView mouseDownCanMoveWindow] || !mIsMovable;
	}
	
	mInitialDragLocation = [event locationInWindow];
	mInitialDragLocationOnScreen = [self convertRectToScreen:(NSRect){[event locationInWindow], [self frame].size}].origin;
	
	mInitialWindowFrameForDrag = [self frame];
	mDragShouldResizeWindow = (mInitialDragLocation.x > mInitialWindowFrameForDrag.size.width - kBKBorderlessWindowResizerSize.width && 
							   mInitialDragLocation.y < kBKBorderlessWindowResizerSize.height);
	
	//From <http://cs.oberlin.edu/~dadamson/DragonDrop/>
	if(mDragShouldResizeWindow && [self respondsToSelector:@selector(_startLiveResize)])
		[self performSelector:@selector(_startLiveResize)];
}

#pragma mark - • Keyboard

- (void)keyDown:(NSEvent *)event
{
	if([mKeyListener dispatchKey:[event keyCode] withModifiers:[event modifierFlags]])
		return;
	
	[super keyDown:event];
}

#pragma mark - • Gestures

- (void)magnifyWithEvent:(NSEvent *)event
{
	if([[self delegate] respondsToSelector:@selector(window:wasMagnifiedWithEvent:)])
	{
		if([[self delegate] window:self wasMagnifiedWithEvent:event])
			return;
	}
	
	[super magnifyWithEvent:event];
}

- (void)rotateWithEvent:(NSEvent *)event
{
	if([[self delegate] respondsToSelector:@selector(window:wasRotatedWithEvent:)])
	{
		if([[self delegate] window:self wasRotatedWithEvent:event])
			return;
	}
	
	[super magnifyWithEvent:event];
}

- (void)swipeWithEvent:(NSEvent *)event
{
	if([[self delegate] respondsToSelector:@selector(window:wasSwipedWithEvent:)])
	{
		if([[self delegate] window:self wasSwipedWithEvent:event])
			return;
	}
	
	[super magnifyWithEvent:event];
}

@end
