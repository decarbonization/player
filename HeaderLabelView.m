//
//  HeaderLabelView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/25/11.
//  Copyright (c) 2011 Roundabout Software, LLC. All rights reserved.
//

#import "HeaderLabelView.h"
#import "AMIndeterminateProgressIndicatorCell.h"

static CGFloat const kSpinnerSize = 14.0;
static CGFloat const kSpinnerMargin = 4.0;

@implementation HeaderLabelView

#pragma mark Globals

+ (NSDictionary *)commonStringDrawingAttributesWithUniqueAttributes:(NSDictionary *)uniqueAttributes
{
	NSMutableDictionary *commonAttributes = [@{NSFontAttributeName: [NSFont systemFontOfSize:13.0], NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.45], 0.0, NSMakeSize(0.0, -1.0))} mutableCopy];
	[commonAttributes setValuesForKeysWithDictionary:uniqueAttributes];
	return [commonAttributes copy];
}

+ (NSDictionary *)foregroundStringDrawingAttributes
{
	static NSDictionary *foregroundStringDrawingAttributes = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		foregroundStringDrawingAttributes = [self commonStringDrawingAttributesWithUniqueAttributes:@{NSForegroundColorAttributeName: [[NSColor windowFrameTextColor] colorWithAlphaComponent:0.75]}];
	});
	
	return foregroundStringDrawingAttributes;
}

+ (NSDictionary *)highlightedStringDrawingAttributes
{
	static NSDictionary *highlightedStringDrawingAttributes = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		highlightedStringDrawingAttributes = [self commonStringDrawingAttributesWithUniqueAttributes:@{NSForegroundColorAttributeName: [NSColor whiteColor], NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.5], 1.0, NSMakeSize(0.0, -1.0))}];
	});
	
	return highlightedStringDrawingAttributes;
}

+ (NSDictionary *)backgroundStringDrawingAttributes
{
	static NSDictionary *backgroundStringDrawingAttributes = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		backgroundStringDrawingAttributes = [self commonStringDrawingAttributesWithUniqueAttributes:@{NSForegroundColorAttributeName: [[NSColor windowFrameTextColor] colorWithAlphaComponent:0.5]}];
	});
	
	return backgroundStringDrawingAttributes;
}

+ (NSGradient *)buttonGradient
{
	static NSGradient *gradient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.00] 
												 endingColor:[NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.00]];
	});
	return gradient;
}

#pragma mark - Internal Gunk

- (id)initWithFrame:(NSRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		mSpinner = [AMIndeterminateProgressIndicatorCell new];
		
		mString = @"Header";
		mLeftMargin = 0.0;
		mRightMargin = 5.0;
	}
	
	return self;
}

- (void)viewDidMoveToWindow
{
	[[self window] setAcceptsMouseMovedEvents:YES];
	
	[self updateTrackingAreas];
}

- (void)updateTrackingAreas
{
	if(mHoverTrackingArea)
	{
		[self removeTrackingArea:mHoverTrackingArea];
		mHoverTrackingArea = nil;
	}
	
	NSRect drawingArea = [self bounds];
	if([self window] && !NSEqualSizes(drawingArea.size, NSZeroSize))
	{
		mHoverTrackingArea = [[NSTrackingArea alloc] initWithRect:[self stringDrawingRectWithBounds:drawingArea]
														  options:(NSTrackingAssumeInside | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow)
															owner:self
														 userInfo:nil];
		
		[self addTrackingArea:mHoverTrackingArea];
	}
}

#pragma mark - Drawing

- (BOOL)isKey
{
	return [[self window] isKeyWindow];
}

- (NSDictionary *)appropriateStringDrawingAttributes
{
	if([self isKey])
		return [[self class] foregroundStringDrawingAttributes];
	
	return [[self class] backgroundStringDrawingAttributes];
}

- (NSSize)stringDrawingSize
{
	NSDictionary *stringDrawingAttributes = [self appropriateStringDrawingAttributes];
	return [mString sizeWithAttributes:stringDrawingAttributes];
}

- (NSRect)rawStringDrawingRect
{
	NSRect drawingRect = [self bounds];
	NSSize stringSize = [self stringDrawingSize];
	NSPoint stringDrawingPoint = NSMakePoint(NSMidX(drawingRect) - stringSize.width / 2.0, 
											 (NSMidY(drawingRect) - stringSize.height / 2.0) + 1.0);
	
	return (NSRect){ stringDrawingPoint, stringSize };
}

- (NSRect)stringDrawingRectWithBounds:(NSRect)bounds
{
	NSRect rawStringDrawingRect = [self rawStringDrawingRect];
	if(NSMinX(rawStringDrawingRect) <= mLeftMargin)
	{
		rawStringDrawingRect.origin.x += round(mLeftMargin - NSMinX(rawStringDrawingRect));
		if(mShowBusyIndicator)
			rawStringDrawingRect.origin.x += kSpinnerSize + kSpinnerMargin;
		
		if(NSMaxX(rawStringDrawingRect) >= NSMaxX(bounds) - mRightMargin)
			rawStringDrawingRect.size.width -= round(NSMaxX(rawStringDrawingRect) - NSMaxX(bounds)) + mRightMargin;
	}
	
	return NSIntegralRect(rawStringDrawingRect);
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
	if(mString)
	{
		NSRect drawingRect = [self bounds];
		
		NSRect stringRect = [self stringDrawingRectWithBounds:drawingRect];
		
		if(mHighlighted || mMouseInside)
		{
			NSRect highlightRect = NSMakeRect(NSMinX(stringRect) - 7.0, 1.0, NSWidth(stringRect) + 14.0, NSHeight(drawingRect) - 2.0);
			if(mShowBusyIndicator)
			{
				highlightRect.origin.x -= kSpinnerSize + kSpinnerMargin;
				highlightRect.size.width += kSpinnerSize + kSpinnerMargin;
			}
			
			NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:highlightRect 
																		   xRadius:5.0 
																		   yRadius:5.0];
			
			//Draw a drop shadow.
			[NSGraphicsContext saveGraphicsState];
			{
				[RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.8], 1.0, NSMakeSize(0.0, -1.0)) set];
				
				[[NSColor colorWithDeviceWhite:0.0 alpha:0.1] set];
				[backgroundPath fill];
			}
			[NSGraphicsContext restoreGraphicsState];
			
			[[[self class] buttonGradient] drawInBezierPath:backgroundPath angle:90.0];
			
			if(mHighlighted)
			{
				[[NSColor clearColor] set];
				[backgroundPath fillWithInnerShadow:RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.65], 5.0, NSMakeSize(0.0, -1.0))];
			}
			
			[[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
			[backgroundPath strokeInside];
		}
		
		[mString drawWithRect:stringRect 
					  options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) 
				   attributes:[self appropriateStringDrawingAttributes]];
		
		if(mShowBusyIndicator)
		{
			NSRect spinnerFrame = NSMakeRect(NSMinX(stringRect) - kSpinnerSize - kSpinnerMargin, NSMidY(drawingRect) - kSpinnerSize / 2.0, 
											 kSpinnerSize, kSpinnerSize);
			[mSpinner drawWithFrame:spinnerFrame inView:self];
		}
	}
}

#pragma mark - Spinner Heart Beat

- (void)spinnerHeartBeat:(NSTimer *)timer
{
	double value = fmod(([mSpinner doubleValue] + (5.0 / 60.0)), 1.0);
	[mSpinner setDoubleValue:value];
	
	[self setNeedsDisplay:YES];
}

#pragma mark - Properties

@synthesize string = mString;
- (void)setString:(NSString *)string
{
	mString = [string copy];
	[self setNeedsDisplay:YES];
	
	[self updateTrackingAreas];
}

@synthesize leftMargin = mLeftMargin;
- (void)setLeftMargin:(CGFloat)leftMargin
{
	mLeftMargin = leftMargin;
	[self setNeedsDisplay:YES];
	
	[self updateTrackingAreas];
}

@synthesize rightMargin = mRightMargin;
- (void)setRightMargin:(CGFloat)rightMargin
{
	mRightMargin = rightMargin;
	[self setNeedsDisplay:YES];
	
	[self updateTrackingAreas];
}

@synthesize showBusyIndicator = mShowBusyIndicator;
- (void)setShowBusyIndicator:(BOOL)showBusyIndicator
{
	if(mShowBusyIndicator == showBusyIndicator)
		return;
	
	[mSpinner setSpinning:showBusyIndicator];
	mShowBusyIndicator = showBusyIndicator;
	if(mShowBusyIndicator)
	{
		mSpinnerHeartBeat = [NSTimer scheduledTimerWithTimeInterval:[mSpinner animationDelay] 
															 target:self 
														   selector:@selector(spinnerHeartBeat:) 
														   userInfo:nil 
															repeats:YES];
	}
	else
	{
		[mSpinnerHeartBeat invalidate];
		mSpinnerHeartBeat = nil;
	}
	
	[self setNeedsDisplay:YES];
	
	[self updateTrackingAreas];
}

#pragma mark -

@synthesize clickable = mClickable;
@synthesize action = mAction;
@synthesize target = mTarget;

#pragma mark - Events

- (BOOL)mouseDownCanMoveWindow
{
	return ![self action] || (mMouseDownCanMoveWindow && !mHighlighted);
}

#pragma mark -

- (void)mouseExited:(NSEvent *)event
{
	if(![self action] || !mClickable)
		return;
	
	mMouseInside = NO;
	mHighlighted = NO;
	[self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)event
{
	if(![self action] || !mClickable)
		return;
	
	mMouseInside = YES;
	
	if(mMouseIsPressed)
		mHighlighted = YES;
	
	[self setNeedsDisplay:YES];
}

#pragma mark -

- (void)mouseUp:(NSEvent *)event
{
	mMouseIsPressed = NO;
	
	NSPoint mousePointInView = [self convertPoint:[event locationInWindow] fromView:nil];
	BOOL isMouseInClickableArea = mClickable && NSPointInRect(mousePointInView, [self stringDrawingRectWithBounds:[self bounds]]);
	if([self mouseDownCanMoveWindow] || !isMouseInClickableArea)
	{
		[super mouseUp:event];
		mMouseDownCanMoveWindow = NO;
		return;
	}
	
	mMouseInside = NO;
	if(mHighlighted)
	{
		mHighlighted = NO;
		[self setNeedsDisplay:YES];
		
		if(mAction)
		{
			NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
			if(NSPointInRect(mousePoint, [self bounds]))
			{
				[NSApp sendAction:mAction to:mTarget from:self];
			}
		}
	}
}

- (void)mouseDragged:(NSEvent *)event
{
	if(mMouseIsPressed)
		return;
	
	mMouseDownCanMoveWindow = YES;
	[super mouseDragged:event];
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint mousePointInView = [self convertPoint:[event locationInWindow] fromView:nil];
	BOOL isMouseInClickableArea = mClickable && NSPointInRect(mousePointInView, [self stringDrawingRectWithBounds:[self bounds]]);
	if([self mouseDownCanMoveWindow] || !isMouseInClickableArea)
	{
		mMouseDownCanMoveWindow = YES;
		[super mouseDown:event];
		return;
	}
	
	mMouseIsPressed = YES;
	
	mHighlighted = YES;
	[self setNeedsDisplay:YES];
}

@end
