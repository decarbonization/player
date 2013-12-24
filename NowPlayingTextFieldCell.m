//
//  NowPlayingTextFieldCell.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 9/17/12.
//
//

#import "NowPlayingTextFieldCell.h"

@implementation NowPlayingTextFieldCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSShadow *shadow = RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.6], 0.1, NSMakeSize(0.0, -1.0));
	
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	
	[super drawWithFrame:cellFrame inView:controlView];
	
	[NSGraphicsContext restoreGraphicsState];    
}

@end
