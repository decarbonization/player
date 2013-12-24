//
//  NSBezierPath+MCAdditions.h
//
//  Created by Sean Patrick O'Brien on 4/1/08.
//  Copyright 2008 MolokoCacao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#pragma once

///The struct used to describe corner radii for a bezier path.
typedef struct NSBezierPathCornerRadii {
	
	CGFloat topLeft;
	CGFloat topRight;
	CGFloat bottomLeft;
	CGFloat bottomRight;
	
} NSBezierPathCornerRadii;

RK_INLINE NSBezierPathCornerRadii NSBezierPathCornerRadiiMake(CGFloat topLeft, CGFloat topRight, CGFloat bottomLeft, CGFloat bottomRight)
{
	return (NSBezierPathCornerRadii){
		.topLeft = topLeft,
		.topRight = topRight,
		.bottomLeft = bottomLeft, 
		.bottomRight = bottomRight,
	};
}

@interface NSBezierPath (MCAdditions)

+ (NSBezierPath *)bezierPathWithRect:(NSRect)rect cornerRadii:(NSBezierPathCornerRadii)cornerRadii;

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef;
- (CGPathRef)cgPath;

- (NSBezierPath *)pathWithStrokeWidth:(CGFloat)strokeWidth;

- (void)fillWithInnerShadow:(NSShadow *)shadow;
- (void)drawBlurWithColor:(NSColor *)color radius:(CGFloat)radius;

- (void)strokeInside;
- (void)strokeInsideWithinRect:(NSRect)clipRect;

@end
