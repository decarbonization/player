//
//  ScrubbingBarView.m
//  Pinna
//
//  Created by Peter MacWhinnie on 1/21/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "ScrubbingBarView.h"

static NSGradient *kFillGradient = nil, 
				  *kHighlightGradient = nil;

static NSDictionary *kTimeStampTextAttributes = nil;
static CGFloat const kTimeStampTextPadding = 1.0;
static CGFloat const kScrubberInteriorPadding = 2.0;
static CGFloat const kTimeStampDefaultWidth = 40.0, kTimeStampDefaultRemainingWidth = 40.0;
static NSUInteger const kNumberOfStrikes = 5;

@implementation ScrubbingBarView

+ (void)initialize
{
	if(!kFillGradient)
	{
		kFillGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.55]
													  endingColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.75]];
		
		kHighlightGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.01 green:0.29 blue:0.91 alpha:1.0]
														   endingColor:[NSColor colorWithCalibratedRed:0.01 green:0.52 blue:0.91 alpha:1.0]];
		
		NSMutableParagraphStyle *timeStampParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[timeStampParagraphStyle setAlignment:NSCenterTextAlignment];
		kTimeStampTextAttributes = @{
            NSFontAttributeName: [NSFont fontWithName:@"MavenProMedium" size:11.8],
            NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.52],
            NSParagraphStyleAttributeName: timeStampParagraphStyle,
            NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.6], 0.1, NSMakeSize(0.0, -1.0)),
        };
	}
	
	[super initialize];
}

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect]))
	{
		mDuration = 0.0;
		
		self.currentTime = 0.0;
	}
	
	return self;
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect drawingArea = [self bounds];
	
	if(mTimeStampDisplayString)
	{
		NSRect timeStampRect = NSMakeRect(NSMaxX(drawingArea) - mTimeStampWidth,
										  (NSMidY(drawingArea) - (mTimeStampDisplayStringSize.height / 2.0)),
										  mTimeStampWidth,
										  mTimeStampDisplayStringSize.height);
		
		[mTimeStampDisplayString drawWithRect:timeStampRect
									  options:NSStringDrawingUsesLineFragmentOrigin
								   attributes:kTimeStampTextAttributes];
		
		drawingArea.size.width -= round(mTimeStampWidth + kTimeStampTextPadding);
	}
	
	NSImage *strikeImage = [NSImage imageNamed:@"ScrubbingBarStrike"];
	NSSize strikeSize = [strikeImage size];
	CGFloat areaBetweenStrikes = (NSWidth(drawingArea) - 7.0) / (kNumberOfStrikes - 1);
	NSRect strikeDrawingRect = NSMakeRect(3.0,
										  0.0,
										  strikeSize.width,
										  strikeSize.height);
	
	//Draw the first strike
	strikeDrawingRect.origin.y = 2.0;
	
	[strikeImage drawInRect:strikeDrawingRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver
				   fraction:1.0
			 respectFlipped:YES
					  hints:nil];
	
	//Draw the middle strikes
	for (NSUInteger strike = 1; strike < kNumberOfStrikes; strike++)
	{
		if(strike == 2)
			strikeDrawingRect.origin.y = 1.0;
		else
			strikeDrawingRect.origin.y = 2.0;
		
		[strikeImage drawInRect:strikeDrawingRect
					   fromRect:NSZeroRect
					  operation:NSCompositeSourceOver
					   fraction:1.0
				 respectFlipped:YES
						  hints:nil];
		
		strikeDrawingRect.origin.x += round(areaBetweenStrikes);
	}
	
	//Draw the last strike
	strikeDrawingRect.origin.y = 2.0;
	strikeDrawingRect.origin.x = NSMaxX(drawingArea) - (NSWidth(strikeDrawingRect) + 3.0);
	
	[strikeImage drawInRect:strikeDrawingRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver
				   fraction:1.0
			 respectFlipped:YES
					  hints:nil];
	
	drawingArea.origin.y += (strikeSize.height - 3.0);
	drawingArea.size.height -= (strikeSize.height + 3.0);
	
	NSSize scrubbingBarFillSize = [[NSImage imageNamed:@"ScrubbingBarBackground_Fill"] size];
	
	NSRect backgroundDrawingArea = NSMakeRect(NSMinX(drawingArea),
											  round(NSMidY(drawingArea) - scrubbingBarFillSize.height / 2.0),
											  NSWidth(drawingArea),
											  scrubbingBarFillSize.height);
	NSDrawThreePartImage(backgroundDrawingArea,
						 [NSImage imageNamed:@"ScrubbingBarBackground_LeftCap"],
						 [NSImage imageNamed:@"ScrubbingBarBackground_Fill"],
						 [NSImage imageNamed:@"ScrubbingBarBackground_RightCap"],
						 NO,
						 NSCompositeSourceOver,
						 1.0,
						 NO);
	
	if(mDuration != 0.0 || (mDuration == 0.0 && mCurrentTime != 0.0))
	{
		CGFloat currentTime = mDuration == 0.0? 0.0 : mCurrentTime;
		CGFloat opacity = (mDuration == 0.0 && mCurrentTime != 0.0)? 0.85 : 1.0;
		
		NSImage *dialImage = [NSImage imageNamed:@"ScrubbingBarDial"];
		NSSize dialSize = [dialImage size];
		
		NSSize scrubbingBarKnobFillSize = [[NSImage imageNamed:@"ScrubbingBarKnob_Fill"] size];
		
		NSRect valueSegmentArea = NSMakeRect(NSMinX(drawingArea) + 3.0,
											 round(NSMidY(drawingArea) - scrubbingBarKnobFillSize.height / 2.0) + 1.0,
											 NSWidth(drawingArea) - 9.0,
											 scrubbingBarKnobFillSize.height);
		valueSegmentArea.size.width = MAX(round(dialSize.width / 3.0), round(NSWidth(valueSegmentArea) * (currentTime > 0.0 && mDuration > 0.0? currentTime / mDuration : 0.0)));
		
		NSDrawThreePartImage(valueSegmentArea,
							 [NSImage imageNamed:@"ScrubbingBarKnob_LeftCap"],
							 [NSImage imageNamed:@"ScrubbingBarKnob_Fill"],
							 [NSImage imageNamed:@"ScrubbingBarKnob_RightCap"],
							 NO,
							 NSCompositeSourceOver,
							 opacity,
							 NO);
		
		NSRect dialDrawingRect = NSMakeRect(round(NSMaxX(valueSegmentArea) - dialSize.width / 2.0),
											round(NSMidY(drawingArea) - dialSize.height / 2.0),
											dialSize.width,
											dialSize.height);
		[dialImage drawInRect:dialDrawingRect
					 fromRect:NSZeroRect
					operation:NSCompositeSourceOver
					 fraction:1.0
			   respectFlipped:YES
						hints:nil];
	}
}

#pragma mark - Properties

- (void)setDuration:(NSTimeInterval)value
{
	mDuration = value;
	
	if(mCurrentTime > value)
	{
		self.currentTime = value;
		return;
	}
	
	[self setNeedsDisplay:YES];
}

- (NSTimeInterval)duration
{
	return mDuration;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
	if(currentTime > mDuration && mDuration != 0.0)
		currentTime = mDuration;
	
	mCurrentTime = currentTime;
	
	if(mDuration == 0.0 && mCurrentTime == 0.0)
	{
		mTimeStampDisplayString = @"-:--";
	}
	else if(mDuration == 0.0 && mCurrentTime != 0.0)
	{
		mTimeStampDisplayString = [@"+" stringByAppendingString:RKMakeStringFromTimeInterval(currentTime)];
	}
	else
	{
		if(mUseTimeRemainingDisplayStyle)
		{
			mTimeStampDisplayString = [@"-" stringByAppendingString:RKMakeStringFromTimeInterval(mDuration - currentTime)];
		}
		else
		{
			mTimeStampDisplayString = RKMakeStringFromTimeInterval(currentTime);
		}
	}
	
	mTimeStampDisplayStringSize = [mTimeStampDisplayString sizeWithAttributes:kTimeStampTextAttributes];
	mTimeStampWidth = MAX(mTimeStampDisplayStringSize.width,
						  mUseTimeRemainingDisplayStyle? kTimeStampDefaultRemainingWidth : kTimeStampDefaultWidth);
	
	[self setNeedsDisplay:YES];
}

- (NSTimeInterval)currentTime
{
	return mCurrentTime;
}

#pragma mark -

- (void)setUseTimeRemainingDisplayStyle:(BOOL)useTimeRemainingDisplayStyle
{
	mUseTimeRemainingDisplayStyle = useTimeRemainingDisplayStyle;
	
	self.currentTime = self.currentTime;
}

- (BOOL)useTimeRemainingDisplayStyle
{
	return mUseTimeRemainingDisplayStyle;
}

#pragma mark -

@synthesize action = mAction;

#pragma mark - Events

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

- (void)mouseUp:(NSEvent *)event
{
	if(mDuration == 0.0)
		return;
	
	NSPoint pointInView = [self convertPoint:[event locationInWindow] fromView:nil];
	CGFloat scrubberWidth = NSWidth([self frame]) - (mTimeStampWidth + kTimeStampTextPadding + (kScrubberInteriorPadding * 2.0));
	if(pointInView.x > scrubberWidth)
	{
		self.useTimeRemainingDisplayStyle = !self.useTimeRemainingDisplayStyle;
	}
	else
	{
		double newValue = mDuration * (pointInView.x > 0.0? pointInView.x / scrubberWidth : 0.0);
		self.currentTime = newValue;
		
		if(mAction)
			mAction();
	}
}

- (void)mouseDragged:(NSEvent *)event
{
	if(mDuration == 0.0)
		return;
	
	NSPoint pointInView = [self convertPoint:[event locationInWindow] fromView:nil];
	CGFloat scrubberWidth = NSWidth([self frame]) - (mTimeStampWidth + kTimeStampTextPadding + (kScrubberInteriorPadding * 2.0));
	if(pointInView.x < scrubberWidth)
	{
		double newValue = mDuration * (pointInView.x > 0.0? pointInView.x / scrubberWidth : 0.0);
		self.currentTime = newValue;
		
		if(mAction)
			mAction();
	}
}

- (void)mouseDown:(NSEvent *)event
{
	
}

@end
