//
//  SearchBarButtonCell.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/15/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "SearchBarButtonCell.h"

@implementation SearchBarButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	if([self isHighlighted])
	{
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.05] set];
		[NSBezierPath fillRect:NSMakeRect(NSMinX(frame), NSMinY(frame), NSWidth(frame) - 2.0, NSHeight(frame))];
	}
	
	[[NSColor colorWithDeviceWhite:0.0 alpha:0.25] set];
	[NSBezierPath fillRect:NSMakeRect(NSMaxX(frame) - 2.0, NSMinY(frame), 1.0, NSHeight(frame))];
	[[NSColor colorWithDeviceWhite:1.0 alpha:0.45] set];
	[NSBezierPath fillRect:NSMakeRect(NSMaxX(frame) - 1.0, NSMinY(frame), 1.0, NSHeight(frame))];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.size.height -= 3.0;
	cellFrame.size.width -= 2.0;
	cellFrame.origin.y += 3.0;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
