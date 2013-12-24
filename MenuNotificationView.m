//
//  BackgroundStatusView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 9/7/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "MenuNotificationView.h"
#import <Quartz/Quartz.h>
#import "RKAnimator.h"

static CGFloat const kPadding = 5.0;
static CGFloat const kInteriorPadding = 3.0;
static CGFloat const kIconWidth = 16.0;

static NSDictionary *_TitleAttributes = nil;

@implementation MenuNotificationView

#pragma mark Initialization

+ (void)initialize
{
	if(!_TitleAttributes)
	{
		_TitleAttributes = @{
            NSForegroundColorAttributeName: [NSColor blackColor],
            NSFontAttributeName: [NSFont boldSystemFontOfSize:11.0],
            NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.45], 0.0, NSMakeSize(0.0, -1.0)),
        };
	}
	
	[super initialize];
}

- (id)init
{
	CGFloat systemStatusBarHeight = [[NSStatusBar systemStatusBar] thickness];
	
	if((self = [super initWithFrame:NSMakeRect(0.0, 0.0, systemStatusBarHeight, systemStatusBarHeight)]))
	{
		mTitle = [[NSProcessInfo processInfo] processName];
	}
	
	return self;
}

#pragma mark - Drawing

- (void)viewDidMoveToSuperview
{
	[self setWantsLayer:YES];
}

- (NSSize)preferredSize
{
	CGFloat systemStatusBarHeight = [[NSStatusBar systemStatusBar] thickness];
	
	NSSize preferredSize = NSMakeSize(kPadding * 2.0, systemStatusBarHeight);
	
	if(mTitle)
	{
		preferredSize.width += MIN(100.0, [mTitle sizeWithAttributes:_TitleAttributes].width);
		preferredSize.width += kInteriorPadding;
	}
	preferredSize.width += kIconWidth;
	
	return preferredSize;
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect drawingRect = [self bounds];
	
	if(mHighlighted)
	{
		
	}
	
	
	NSSize preferredTextSize = mTitle? [mTitle sizeWithAttributes:_TitleAttributes] : NSZeroSize;
	if(preferredTextSize.width > 100.0)
		preferredTextSize.width = 100.0;
	
	NSImage *icon = mIsPaused? [NSImage imageNamed:@"NotificationIcon_Paused"] : [NSImage imageNamed:@"NotificationIcon_Playing"];
	NSSize iconSize = icon.size;
	
	NSRect imageRect = NSMakeRect(NSMinX(drawingRect) + kPadding, 
								  NSMidY(drawingRect) - (iconSize.height / 2.0), 
								  iconSize.height, 
								  iconSize.width);
	
	[icon setFlipped:NO];
	[icon drawInRect:imageRect 
			fromRect:NSZeroRect 
		   operation:NSCompositeSourceOver 
			fraction:1.0 
	  respectFlipped:YES 
			   hints:nil];
	
	drawingRect.size.width -= NSMaxX(imageRect);
	drawingRect.origin.x += NSMaxX(imageRect);
	
	if(mTitle)
	{
		NSRect titleRect = NSMakeRect(NSMinX(drawingRect) + kInteriorPadding, 
									  NSMidY(drawingRect) - (preferredTextSize.height / 2.0), 
									  preferredTextSize.width, 
									  preferredTextSize.height);
		
		[mTitle drawWithRect:titleRect 
					 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine) 
				  attributes:_TitleAttributes];
	}
}

#pragma mark - Properties

- (void)setImage:(NSImage *)image
{
	mImage = [image copy];
	
	[mImage setSize:NSMakeSize(14.0, 14.0)];
	
	[self setFrameSize:[self preferredSize]];
	[self setNeedsDisplay:YES];
}

- (NSImage *)image
{
	return [mImage copy];
}

- (NSString *)formatStringForDisplay:(NSString *)string
{
	if(!string)
		return nil;
	
	NSUInteger(^findClosingCharacterLocation)(NSString *, unichar, NSUInteger) = ^NSUInteger(NSString *haystack, unichar needle, NSUInteger index) {
		for (; index < [haystack length]; index++)
		{
			unichar possibleMatch = [haystack characterAtIndex:index];
			if(possibleMatch == needle)
				return index + 1;
		}
		
		return [haystack length];
	};
	
	NSMutableString *newString = [string mutableCopy];
	
	NSInteger indexOfOpeningParen = NSNotFound;
	while ((indexOfOpeningParen = [newString rangeOfString:@"("].location) != NSNotFound)
	{
		if(indexOfOpeningParen != 0 && [newString characterAtIndex:indexOfOpeningParen - 1] == ' ')
			indexOfOpeningParen--;
		
		NSInteger indexOfClosingParen = findClosingCharacterLocation(newString, ')', indexOfOpeningParen);
		[newString deleteCharactersInRange:NSMakeRange(indexOfOpeningParen, indexOfClosingParen - indexOfOpeningParen)];
	}
	
	NSInteger indexOfOpeningBracket = NSNotFound;
	while ((indexOfOpeningBracket = [newString rangeOfString:@"["].location) != NSNotFound)
	{
		if(indexOfOpeningBracket != 0 && [newString characterAtIndex:indexOfOpeningBracket - 1] == ' ')
			indexOfOpeningBracket--;
		
		NSInteger indexOfClosingBracket = findClosingCharacterLocation(newString, ']', indexOfOpeningBracket);
		[newString deleteCharactersInRange:NSMakeRange(indexOfOpeningBracket, indexOfClosingBracket - indexOfOpeningBracket)];
	}
	
	return newString;
}

- (void)setTitle:(NSString *)title
{
	mTitle = [self formatStringForDisplay:title];
	
	[self setFrameSize:[self preferredSize]];
	[self setNeedsDisplay:YES];
}

- (NSString *)title
{
	return [mTitle copy];
}

@synthesize isPaused = mIsPaused;
- (void)setIsPaused:(BOOL)isPaused
{
	mIsPaused = isPaused;
	[self setNeedsDisplay:YES];
}

@synthesize action = mAction;

#pragma mark - Visibility

- (void)show
{
	if([self superview] == nil)
	{
		[self setHidden:YES];
		
		
		mStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[mStatusItem setView:self];
		[self setFrameSize:[self preferredSize]];
		
		[[RKAnimator animator] synchronousTransaction:^(RKAnimatorTransaction *transaction) {
			transaction.duration = 0.3;
			
			[transaction fadeInTarget:self];
		}];
	}
	
	if(mFadeOutTimer)
	{
		[mFadeOutTimer invalidate];
		mFadeOutTimer = nil;
	}
	
	if(!mHighlighted)
		mFadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(close) userInfo:nil repeats:NO];
}

- (void)close
{
	if([self superview] != nil)
	{
		mHighlighted = NO;
		[self setNeedsDisplay:YES];
		
		[[RKAnimator animator] synchronousTransaction:^(RKAnimatorTransaction *transaction) {
			transaction.duration = 0.3;
			transaction.completionHandler = ^(BOOL completed) {
				if(!completed)
					return;
				
				[self removeFromSuperview];
				[[NSStatusBar systemStatusBar] removeStatusItem:mStatusItem];
			};
			
			[transaction fadeOutTarget:[self window]];
		}];
	}
	
	if(mFadeOutTimer)
	{
		[mFadeOutTimer invalidate];
		mFadeOutTimer = nil;
	}
}

#pragma mark - Events

- (void)mouseUp:(NSEvent *)event
{
	if(mAction)
		mAction();
	
	mHighlighted = NO;
	[self setNeedsDisplay:YES];
	
	if([self superview] != nil && !mFadeOutTimer)
	{
		mFadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(close) userInfo:nil repeats:NO];
	}
}

- (void)mouseDown:(NSEvent *)event
{
	mHighlighted = YES;
	[self setNeedsDisplay:YES];
	
	if(mFadeOutTimer)
	{
		[mFadeOutTimer invalidate];
		mFadeOutTimer = nil;
	}
}

@end
