//
//  BrowserSearchFieldCell.m
//  Pinna
//
//  Created by Peter MacWhinnie on 3/13/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "BrowserSearchFieldCell.h"

//#define WE_HAVE_A_CLEAR_BACKGROUND	1

static NSShadow *InnerShadow = nil;
static NSShadow *DropShadow = nil;
static NSGradient *BorderGradient = nil;

@implementation BrowserSearchFieldCell

+ (void)initialize
{
	if(!InnerShadow)
	{
		InnerShadow = RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.15], 2.0, NSMakeSize(0.0, -1.0));
		
		DropShadow = RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.45], 2.0, NSMakeSize(0.0, -1.0));
		
		BorderGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.52 green:0.52 blue:0.52 alpha:0.75] 
													   endingColor:[NSColor colorWithCalibratedRed:0.71 green:0.71 blue:0.71 alpha:0.65]];
	}
	
	[super initialize];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect outerDrawingArea = cellFrame;
	outerDrawingArea.size.height -= 1.0;
	
#if WE_HAVE_A_CLEAR_BACKGROUND
	
#else
	
	NSBezierPath *outerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect:outerDrawingArea 
																		xRadius:NSHeight(outerDrawingArea) / 2.0 
																		yRadius:NSHeight(outerDrawingArea) / 2.0];
	//Draw the field shadow.
	[NSGraphicsContext saveGraphicsState];
	{
		[DropShadow set];
		[[NSColor whiteColor] set];
		[outerBackgroundPath fill];
	}
	[NSGraphicsContext restoreGraphicsState];
	
	//Draw the border (we draw on top of this so that we get a nice crisp line around the field).
	[BorderGradient drawInBezierPath:outerBackgroundPath angle:90.0];
	
	
	NSRect innerDrawingArea = NSInsetRect(outerDrawingArea, 1.0, 1.0);
	
	NSBezierPath *innerBackgroundPath = [NSBezierPath bezierPathWithRoundedRect:innerDrawingArea 
																		xRadius:NSHeight(innerDrawingArea) / 2.0 
																		yRadius:NSHeight(innerDrawingArea) / 2.0];
	
	//Draw the interior background with a nice shadow.
	[[self backgroundColor] set];
	[innerBackgroundPath fill];
	[innerBackgroundPath fillWithInnerShadow:InnerShadow];
	
#endif /* WE_HAVE_A_CLEAR_BACKGROUND */
	
	[self drawInteriorWithFrame:outerDrawingArea inView:controlView];
}

@end
