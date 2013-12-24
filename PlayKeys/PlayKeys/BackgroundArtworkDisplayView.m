//
//  BackgroundArtworkDisplayView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/27/11.
//  Copyright (c) 2011 Roundabout Software, LLC. All rights reserved.
//

#import "BackgroundArtworkDisplayView.h"
#import <Quartz/Quartz.h>
#import "NSBezierPath+MCAdditions.h"

@implementation BackgroundArtworkDisplayView

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect drawingRect = [self bounds];
	
	[[NSColor blackColor] set];
	[NSBezierPath fillRect:drawingRect];
	
	if(_image)
	{
		NSRect imageRect = NSZeroRect;
		imageRect.size = [_image size];
		
		CGFloat delta = drawingRect.size.width / imageRect.size.width;
		imageRect.size.width *= delta;
		imageRect.size.height *= delta;
		imageRect.origin.x = NSMidX(drawingRect) - (NSWidth(imageRect) / 2.0);
		imageRect.origin.y = NSMidY(drawingRect) - (NSHeight(imageRect) / 2.0);
		
		[_image setFlipped:NO];
		[_image drawInRect:imageRect 
				  fromRect:NSZeroRect 
				 operation:NSCompositeSourceOver 
				  fraction:1.0 
			respectFlipped:YES 
					 hints:nil];
		
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
		[[NSBezierPath bezierPathWithRect:drawingRect] strokeInside];
		
        NSRect topLineRect = NSMakeRect(1.0, NSHeight(drawingRect) - 2.0, 
										NSWidth(drawingRect) - 2.0, 1.0);
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.45] set];
		[NSBezierPath fillRect:topLineRect];
	}
}

@end
