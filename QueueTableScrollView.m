//
//  QueueTableScrollView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/4/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "QueueTableScrollView.h"
#import "QueueTableView.h"

@implementation QueueTableScrollView

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

#pragma mark -

- (void)mouseExited:(NSEvent *)event
{
	QueueTableView *targetTableView = [self documentView];
	targetTableView.hoveredUponRow = -1;
}

- (void)mouseMoved:(NSEvent *)event
{
	NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
	QueueTableView *targetTableView = [self documentView];
	NSPoint mouseLocationInTableView = [targetTableView convertPoint:mouseLocation fromView:self];
	
	targetTableView.hoveredUponRow = [targetTableView rowAtPoint:mouseLocationInTableView];
}

@end
