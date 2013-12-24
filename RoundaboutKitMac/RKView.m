//
//  RKView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "RKView.h"

@implementation RKView

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.wantsLayer = YES;
    }
    
    return self;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    [_backgroundColor set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}

#pragma mark - Properties

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    
    [self setNeedsDisplay:YES];
}

@end
