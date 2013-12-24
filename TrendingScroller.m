//
//  TrendingScroller.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 9/16/12.
//
//

#import "TrendingScroller.h"

static NSGradient *BackgroundGradient = nil;
static NSGradient *KnobGradient = nil;

@implementation TrendingScroller

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		BackgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.16 green:0.16 blue:0.16 alpha:1.00]
														   endingColor:[NSColor colorWithCalibratedRed:0.14 green:0.14 blue:0.14 alpha:1.00]];
		KnobGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.82 green:0.82 blue:0.82 alpha:1.00]
													 endingColor:[NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:1.00]];
	});
	
	[super initialize];
}

+ (BOOL)isCompatibleWithOverlayScrollers
{
	return (self == [TrendingScroller class]);
}

#pragma mark - Drawing

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
	if([self scrollerStyle] == NSScrollerStyleOverlay)
	{
		[super drawKnobSlotInRect:slotRect highlight:flag];
		return;
	}
	
	NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRect:slotRect
														cornerRadii:NSBezierPathCornerRadiiMake(0.0, 5.0, 0.0, 0.0)];
	[BackgroundGradient drawInBezierPath:backgroundPath angle:0.0];
	
	NSRect lineRect = NSMakeRect(NSMinX(slotRect), NSMinY(slotRect), 1.0, NSHeight(slotRect));
	[[NSColor blackColor] set];
	[NSBezierPath fillRect:lineRect];
}

- (void)drawKnob
{
	if([self scrollerStyle] == NSScrollerStyleOverlay)
	{
		[super drawKnob];
		return;
	}
	
	NSRect knobRect = NSInsetRect([self rectForPart:NSScrollerKnob], 2.0, 2.0);
	knobRect.origin.x += 1.0;
	knobRect.size.width -= 1.0;
	NSBezierPath *knobPath = [NSBezierPath bezierPathWithRoundedRect:knobRect
															 xRadius:round(NSWidth(knobRect) / 2.0)
															 yRadius:round(NSWidth(knobRect) / 2.0)];
	[KnobGradient drawInBezierPath:knobPath angle:0.0];
}

@end
