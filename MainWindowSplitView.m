//
//  PinnaSplitView.m
//  Pinna
//
//  Created by Peter MacWhinnie on 12/8/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "MainWindowSplitView.h"

static NSGradient *DividerGradient = nil;

@implementation MainWindowSplitView

+ (void)initialize
{
	DividerGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1.00] 
													endingColor:[NSColor colorWithCalibratedRed:0.07 green:0.07 blue:0.07 alpha:1.00]];
	
	[super initialize];
}

#pragma mark - Drawing

- (void)drawDividerInRect:(NSRect)rect
{
	[DividerGradient drawInRect:rect angle:90.0];
}

#pragma mark - Events

- (void)resetCursorRects
{
	
}

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

#pragma mark -


- (void)mouseUp:(NSEvent *)theEvent
{
	[[self nextResponder] mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	[[self nextResponder] mouseDragged:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	[[self nextResponder] mouseMoved:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self nextResponder] mouseDown:theEvent];
}

@end
