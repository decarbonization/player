//
//  BottomBarButtonCell.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 8/4/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "BottomBarButtonCell.h"

@implementation BottomBarButtonCell

- (void)awakeFromNib
{
	[self setBordered:YES];
}

#pragma mark - Drawing

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	//We don't want to draw over the top lines of the bottom bar
	frame.size.height -= 1.0;
	frame.origin.y += 1.0;
	
	if(!mIsRightMostButton)
	{
		[[NSColor colorWithDeviceWhite:0.0 alpha:1.0] set];
		[NSBezierPath fillRect:NSMakeRect(NSMaxX(frame) - 1.0, NSMinY(frame), 
										  1.0, NSHeight(frame))];
		
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.08] set];
		[NSBezierPath fillRect:NSMakeRect(NSMaxX(frame) - 2.0, NSMinY(frame), 
										  1.0, NSHeight(frame))];
	}
	
	if(!mIsLeftMostButton)
	{
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.08] set];
		[NSBezierPath fillRect:NSMakeRect(NSMinX(frame), NSMinY(frame), 
										  1.0, NSHeight(frame))];
	}
	
	if([self state] == NSOnState)
	{
		frame.size.height -= 1.0;
		frame.origin.y += 1.0;
		
		NSBezierPath *backgroundPath = nil;
		if(mIsLeftMostButton)
		{
			frame.size.width -= 2.0;
			backgroundPath = [NSBezierPath bezierPathWithRect:frame 
												  cornerRadii:NSBezierPathCornerRadiiMake(3.0, 0.0, 0.0, 0.0)];
		}
		else if(mIsRightMostButton)
		{
			frame.size.width -= 1.0;
			frame.origin.x += 1.0;
			backgroundPath = [NSBezierPath bezierPathWithRect:frame];
		}
		else
		{
			frame.size.width -= 3.0;
			frame.origin.x += 1.0;
			backgroundPath = [NSBezierPath bezierPathWithRect:frame];
		}
		
		NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.4 alpha:0.00]
																	   endingColor:[NSColor colorWithDeviceWhite:0.76 alpha:0.33]];
		[backgroundGradient drawInBezierPath:backgroundPath angle:90.0];
		
		[backgroundPath fillWithInnerShadow:RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.68], 4.0, NSMakeSize(0.0, -2.0))];
	}
}

#pragma mark - Properties

@synthesize isLeftMostButton = mIsLeftMostButton;
@synthesize isRightMostButton = mIsRightMostButton;

@end
