//
//  SimpleWhiteButton.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 1/2/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "PreferencesButtonCell.h"

static NSGradient *kActiveGradient = nil;
static NSGradient *kInactiveGradient = nil;

@implementation PreferencesButtonCell

+ (void)initialize
{
	kActiveGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.00] 
													endingColor:[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.00]];
	
	kInactiveGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.00] 
													  endingColor:[NSColor colorWithCalibratedRed:0.85 green:0.85 blue:0.85 alpha:1.00]];
	
	[super initialize];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	frame = NSInsetRect(frame, 0.0, 1.0);
	CGFloat borderRadius = _hasSquareCorners? 0.0 : NSHeight(frame) / 2.0;
	
	NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:borderRadius yRadius:borderRadius];
	
	//Draw a drop shadow.
	[NSGraphicsContext saveGraphicsState];
	{
        [RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.8], 1.0, NSMakeSize(0.0, -1.0)) set];
		
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.1] set];
		[backgroundPath fill];
	}
	[NSGraphicsContext restoreGraphicsState];
	
	if([[controlView window] isMainWindow])
	{
		[kActiveGradient drawInBezierPath:backgroundPath angle:90.0];
	}
	else
	{
		[kInactiveGradient drawInBezierPath:backgroundPath angle:90.0];
	}
	
	if([self isHighlighted])
	{
		[[NSColor clearColor] set];
        [RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.85], 5.0, NSMakeSize(0.0, -1.0)) set];
	}
	
	if([[controlView window] isMainWindow] && [self isEnabled])
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.4] set];
	else
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
	
	//Draw the outer border.
	[backgroundPath strokeInside];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSMutableAttributedString *newTitle = [title mutableCopy];
	
	if([self isEnabled])
	{
		[newTitle addAttributes:@{NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.45], 0.0, NSMakeSize(0.0, -1.0))}
						  range:NSMakeRange(0, [newTitle length])];
	}
	else
	{
		[newTitle addAttributes:@{NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.45], 0.0, NSMakeSize(0.0, -1.0))}
						  range:NSMakeRange(0, [newTitle length])];
	}
	
	
	return [super drawTitle:newTitle withFrame:frame inView:controlView];
}

@end
