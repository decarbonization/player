//
//  EtchedTextFieldCell.m
//  Pinna
//
//  Created by Peter MacWhinnie on 6/11/09.
//  Copyright 2009 Roundabout Software, LLC. All rights reserved.
//

#import "EtchedTextFieldCell.h"

@implementation EtchedTextFieldCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSShadow *shadow = [NSShadow new];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.45]];
	[shadow setShadowBlurRadius:0.0];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	
	[super drawWithFrame:cellFrame inView:controlView];
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
