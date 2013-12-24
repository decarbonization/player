//
//  BKShadowedTextFieldCell.m
//  Pinna
//
//  Created by Peter MacWhinnie on 3/20/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "ShadowedTextFieldCell.h"

@implementation ShadowedTextFieldCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSShadow *shadow = [NSShadow new];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.55]];
	[shadow setShadowBlurRadius:1.0];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	
	[super drawWithFrame:cellFrame inView:controlView];
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
