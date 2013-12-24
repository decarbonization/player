//
//  WindowTransition.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/28/11.
//  Copyright (c) 2011 Roundabout Software, LLC. All rights reserved.
//

#import "WindowTransition.h"
#import <Quartz/Quartz.h>

@implementation WindowTransition

- (id)initWithSourceWindow:(NSWindow *)sourceWindow targetWindow:(NSWindow *)targetWindow
{
	NSParameterAssert(sourceWindow);
	NSParameterAssert(targetWindow);
	NSAssert(sourceWindow != targetWindow, @"Source and target windows must be unique.");
	
	if((self = [super init]))
	{
		mSourceWindow = sourceWindow;
		mTargetWindow = targetWindow;
		
		mTransitionWindow = [[NSWindow alloc] initWithContentRect:NSZeroRect 
														styleMask:NSBorderlessWindowMask 
														  backing:NSBackingStoreBuffered 
															defer:NO];
		[mTransitionWindow setOpaque:NO];
		[mTransitionWindow setBackgroundColor:[NSColor clearColor]];
		[mTransitionWindow setReleasedWhenClosed:NO];
		
		mTransitionHostView = [[NSView alloc] initWithFrame:NSZeroRect];
		[mTransitionHostView setLayer:[CALayer layer]];
		[mTransitionHostView setWantsLayer:YES];
		[mTransitionHostView setCanDrawConcurrently:NO];
		
		mTransitionLayer = [CALayer layer];
		mTransitionLayer.shadowColor = CGColorGetConstantColor(kCGColorBlack);
		mTransitionLayer.shadowOffset = CGSizeMake(0.0, -2.0);
		mTransitionLayer.shadowOpacity = 0.5;
		mTransitionLayer.shadowRadius = 3.0;
		
		[[mTransitionHostView layer] addSublayer:mTransitionLayer];
		
		[mTransitionWindow setContentView:mTransitionHostView];
	}
	
	return self;
}

#pragma mark - Properties

@synthesize sourceWindow = mSourceWindow;
@synthesize targetWindow = mTargetWindow;

#pragma mark - Transitioning

- (NSWindow *)topMostWindow
{
	NSArray *orderedWindows = [NSApp orderedWindows];
	if([orderedWindows count] > 0)
		return [orderedWindows objectAtIndex:0];
	
	return nil;
}

- (NSImage *)stillShotOfWindow:(NSWindow *)window
{
	NSView *windowContentView = [window contentView];
	
	NSBitmapImageRep *windowContentsRep = [windowContentView bitmapImageRepForCachingDisplayInRect:[windowContentView bounds]];
	[windowContentView cacheDisplayInRect:[windowContentView bounds] toBitmapImageRep:windowContentsRep];
	
	NSImage *windowContents = [[NSImage alloc] initWithSize:[windowContentView bounds].size];
	[windowContents addRepresentation:windowContentsRep];
	
	return windowContents;
}

#pragma mark -

- (void)transition:(void(^)())completionHandler
{
	completionHandler = [completionHandler copy];
	
	NSRect completeArea = NSUnionRect([mSourceWindow frame], [mTargetWindow frame]);
	completeArea = NSInsetRect(completeArea, -10.0, -10.0);
	[mTransitionWindow setFrame:completeArea display:YES];
	
	NSImage *sourceWindowImage = [self stillShotOfWindow:mSourceWindow];
	NSImage *targetWindowImage = [self stillShotOfWindow:mTargetWindow];
	BOOL shouldActivate = [[self topMostWindow] isEqualTo:mSourceWindow];
	
	[CATransaction begin];
	[CATransaction setAnimationDuration:0.0];
	{
		NSRect targetRect = [mSourceWindow frame];
		targetRect.origin = [mTransitionWindow convertScreenToBase:targetRect.origin];
		mTransitionLayer.frame = targetRect;
		mTransitionLayer.contents = sourceWindowImage;
	}
	[CATransaction commit];
	
	//Disable screen updates...
	NSDisableScreenUpdates();
	{
		[mTransitionWindow orderWindow:NSWindowAbove relativeTo:[mSourceWindow windowNumber]];
		//...and force a display so that we don't get any stutter when
		//transitioning between the actual target window and our facade.
		[mTransitionWindow display];
		
		[mSourceWindow close];
	}
	NSEnableScreenUpdates();
	
	[CATransaction begin];
	[CATransaction setCompletionBlock:^{
		if(completionHandler)
			completionHandler();
		
		NSDisableScreenUpdates();
		{
			[mTargetWindow orderWindow:NSWindowAbove relativeTo:[mTransitionWindow windowNumber]];
			[mTransitionWindow close];
			
			if(shouldActivate)
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					[mTargetWindow makeKeyAndOrderFront:nil];	
				}];
		}
		NSEnableScreenUpdates();
	}];
	{
		NSRect targetRect = [mTargetWindow frame];
		targetRect.origin = [mTransitionWindow convertScreenToBase:targetRect.origin];
		mTransitionLayer.frame = targetRect;
		mTransitionLayer.contents = targetWindowImage;
	}
	
	[CATransaction commit];
}

@end
