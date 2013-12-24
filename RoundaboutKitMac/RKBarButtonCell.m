//
//  RKBarButtonCell.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/7/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKBarButtonCell.h"
#import "NSBezierPath+MCAdditions.h"

#define ARROW_WIDTH         10.0
#define MIN_DEFAULT_WIDTH   30.0
#define BORDER_RADIUS       3.0

static NSGradient *_ActiveGradient = nil;
static NSGradient *_InactiveGradient = nil;
static NSGradient *_HighlightedGradient = nil;

@implementation RKBarButtonCell

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ActiveGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.96 alpha:1.00]
                                                        endingColor:[NSColor colorWithCalibratedRed:0.77 green:0.77 blue:0.77 alpha:1.00]];
        
        _InactiveGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1.00]
                                                          endingColor:[NSColor colorWithCalibratedRed:0.91 green:0.91 blue:0.91 alpha:1.00]];
        
        _HighlightedGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.51 green:0.51 blue:0.51 alpha:1.00]
                                                             endingColor:[NSColor colorWithCalibratedRed:0.62 green:0.62 blue:0.62 alpha:1.00]];
    });
    
    [super initialize];
}

- (RKBarButtonCell *)initWithType:(RKBarButtonType)type title:(NSString *)title
{
    if((self = [super initTextCell:title])) {
        self.buttonType = type;
        
        [self setFont:[NSFont boldSystemFontOfSize:11.0]];
        [self setBezelStyle:NSTexturedSquareBezelStyle];
        [self setHighlightsBy:NSMomentaryLight];
        [self setTitle:title];
    }
    
    return self;
}

#pragma mark - Sizing

- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width = MAX(MIN_DEFAULT_WIDTH, cellSize.width) + 10.0;
    
    if(_buttonType == kRKBarButtonTypeBackButton) {
        cellSize.width += ARROW_WIDTH;
    }
    
    cellSize.height = 23.0;
    
    return cellSize;
}

#pragma mark - Drawing

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSBezierPath *backgroundPath = nil;
	if(_buttonType == kRKBarButtonTypeBackButton) {
		backgroundPath = [NSBezierPath bezierPath];
		[backgroundPath setLineWidth:1.0];
		[backgroundPath moveToPoint:frame.origin];
		
		//Start at the bottom.
		[backgroundPath moveToPoint:NSMakePoint(NSMinX(frame), NSMidY(frame))];
		
		//Draw a line from the centre point to the upper left corner.
		[backgroundPath lineToPoint:NSMakePoint(NSMinX(frame) + ARROW_WIDTH, NSMaxY(frame))];
		
		//Draw a line from the last point to the upper right corner.
		[backgroundPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(frame), NSMaxY(frame))
												 toPoint:NSMakePoint(NSMaxX(frame), NSMaxY(frame) - BORDER_RADIUS)
												  radius:BORDER_RADIUS];
		
		//Draw a line from the last point to the lower right corner.
		[backgroundPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(frame), NSMinY(frame))
												 toPoint:NSMakePoint(NSMaxX(frame) - BORDER_RADIUS, NSMinY(frame))
												  radius:BORDER_RADIUS];
		
		//Draw a line from the last point to the centre point on the left side.
		[backgroundPath lineToPoint:NSMakePoint(NSMinX(frame) + ARROW_WIDTH, NSMinY(frame))];
		
		//Close the path so stroking looks right.
		[backgroundPath closePath];
	} else if(_buttonType == kRKBarButtonTypeDefault) {
		backgroundPath = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:BORDER_RADIUS yRadius:BORDER_RADIUS];
	}
    
    if(self.isHighlighted) {
        [_HighlightedGradient drawInBezierPath:backgroundPath angle:90.0];
        
        NSShadow *innerShadow = [NSShadow new];
        [innerShadow setShadowBlurRadius:4.0];
        [innerShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [innerShadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.4]];
        [backgroundPath fillWithInnerShadow:innerShadow];
        
        [[NSColor colorWithCalibratedRed:0.42 green:0.42 blue:0.42 alpha:1.00] set];
    } else {
        if([[controlView window] isMainWindow]) {
            [_ActiveGradient drawInBezierPath:backgroundPath angle:90.0];
            [[NSColor colorWithCalibratedRed:0.42 green:0.42 blue:0.42 alpha:1.00] set];
        } else {
            [_InactiveGradient drawInBezierPath:backgroundPath angle:90.0];
            [[NSColor colorWithCalibratedRed:0.75 green:0.75 blue:0.75 alpha:1.00] set];
        }
    }
    
    [backgroundPath strokeInside];
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
    if(_buttonType == kRKBarButtonTypeBackButton) {
        frame.origin.x += ARROW_WIDTH - 2.0;
        frame.size.width -= ARROW_WIDTH;
    } else if(_buttonType == kRKBarButtonTypeDefault) {
    }
    
    [super drawImage:image withFrame:frame inView:controlView];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    if(_buttonType == kRKBarButtonTypeBackButton) {
        frame.origin.x += ARROW_WIDTH - 2.0;
        frame.size.width -= ARROW_WIDTH;
    } else if(_buttonType == kRKBarButtonTypeDefault) {
    }
    
    frame.origin.y += 1.0;
    
    return [super drawTitle:title withFrame:frame inView:controlView];
}

@end
