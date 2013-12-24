//
//  RKChromeView.m
//  Pinna
//
//  Created by Peter MacWhinnie on 12/6/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "RKChromeView.h"
#import "RKMacPrelude.h"
#import "RKBorderlessWindow.h"
#import "NSBezierPath+MCAdditions.h"

static NSGradient *_ImageReflectionShadowGradient = nil;

@implementation RKChromeView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)initialize
{
	if(!_ImageReflectionShadowGradient)
		_ImageReflectionShadowGradient = [[NSGradient alloc] initWithStartingColor:[NSColor blackColor] 
																	   endingColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.5]];
	
	[super initialize];
}

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect]))
	{
		mHasTopLine = YES;
		mHasBottomLine = YES;
		mImageHasReflection = YES;
		mShouldDrawImageAboveGradient = YES;
        
		[self setPostsBoundsChangedNotifications:YES];
		[self setPostsFrameChangedNotifications:YES];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(viewDidChange:) 
													 name:NSViewBoundsDidChangeNotification 
												   object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(viewDidChange:) 
													 name:NSViewFrameDidChangeNotification 
												   object:self];
	}
	return self;
}

#pragma mark -

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSWindowDidBecomeMainNotification 
												  object:[self window]];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSWindowDidResignMainNotification 
												  object:[self window]];
}

- (void)viewDidChange:(NSNotification *)notification
{
	if(mTrackingArea)
	{
		[self removeTrackingRect:mTrackingArea];
		mTrackingArea = 0;
	}
	
	mTrackingArea = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
}

- (void)viewDidMoveToWindow
{
	if(mTrackingArea)
	{
		[self removeTrackingRect:mTrackingArea];
		mTrackingArea = 0;
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResizeNotification object:nil];
	}
	
	NSWindow *window = [self window];
	if(window)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(windowDidChangeMain:) 
													 name:NSWindowDidBecomeMainNotification 
												   object:window];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(windowDidChangeMain:) 
													 name:NSWindowDidResignMainNotification 
												   object:window];
		
		mTrackingArea = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
	}
}

- (void)windowDidChangeMain:(NSNotification *)notification
{
	[self setNeedsDisplayInRect:[self bounds]];
}

#pragma mark -

- (void)drawImageInBackgroundPath:(NSBezierPath *)backroundPath withDrawingRect:(NSRect)drawingRect
{
    if(mImage)
    {
        if(mShouldTileImage)
        {
            [[NSColor colorWithPatternImage:mImage] set];
            [NSBezierPath fillRect:drawingRect];
        }
        else
        {
            NSRect imageRect = NSZeroRect;
            imageRect.size = [mImage size];
            
            CGFloat deltaWidth = drawingRect.size.width / imageRect.size.width;
            imageRect.size.width *= deltaWidth;
            imageRect.size.height *= deltaWidth;
            imageRect.origin.x = round(NSMidX(drawingRect) - NSWidth(imageRect) / 2.0);
            imageRect.origin.y = round(NSMidY(drawingRect) - NSHeight(imageRect) / 2.0);
            
            if(NSHeight(imageRect) > NSHeight(drawingRect))
                imageRect.origin.y /= 2.0;
            
            [mImage setFlipped:NO];
            
            [NSGraphicsContext saveGraphicsState];
            {
                if([[self window] inLiveResize])
                    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
                else
                    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
                
				if(mImageShadow && !mImageHasReflection)
				{
					[NSGraphicsContext saveGraphicsState];
					{
						[mImageShadow set];
						[[NSColor blackColor] set];
						[NSBezierPath fillRect:imageRect];
					}
					[NSGraphicsContext restoreGraphicsState];
				}
				
                [mImage drawInRect:imageRect 
                          fromRect:NSZeroRect 
                         operation:NSCompositeSourceOver 
                          fraction:1.0 
                    respectFlipped:NO 
                             hints:nil];
            }
            [NSGraphicsContext restoreGraphicsState];
            
            //We only draw the shadow if it's going to be visible.
            if(mImageHasReflection && (NSHeight(imageRect) <= NSHeight(drawingRect)))
            {
                NSRect reflectionRect = imageRect;
                reflectionRect.origin.y = (NSMinY(imageRect) - NSHeight(imageRect));
                
                [mImage setFlipped:YES];
                [mImage drawInRect:reflectionRect 
                          fromRect:NSZeroRect 
                         operation:NSCompositeSourceOver 
                          fraction:1.0 
                    respectFlipped:NO 
                             hints:nil];
                
                [_ImageReflectionShadowGradient drawInRect:reflectionRect angle:90.0];
            }
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect drawingRect = [self bounds];
	NSBezierPath *backgroundPath = [NSBezierPath bezierPath];
	
	//Start in the left centre.
	[backgroundPath moveToPoint:NSMakePoint(NSMinX(drawingRect), NSMidY(drawingRect))];
	
	if(mTopLeftCornerRadius)
	{
		[backgroundPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(drawingRect), NSMaxY(drawingRect)) 
												 toPoint:NSMakePoint(NSMinX(drawingRect) + mTopLeftCornerRadius, NSMaxY(drawingRect)) 
												  radius:mTopLeftCornerRadius];
	}
	else
	{
		[backgroundPath lineToPoint:NSMakePoint(NSMinX(drawingRect), NSMaxY(drawingRect))];
	}
	
	if(mTopRightCornerRadius)
	{
		[backgroundPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(drawingRect), NSMaxY(drawingRect)) 
												 toPoint:NSMakePoint(NSMaxX(drawingRect), NSMaxY(drawingRect) - mTopRightCornerRadius) 
												  radius:mTopRightCornerRadius];
	}
	else
	{
		[backgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingRect), NSMaxY(drawingRect))];
	}
	
	if(mBottomRightCornerRadius)
	{
		[backgroundPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(drawingRect), NSMinY(drawingRect)) 
												 toPoint:NSMakePoint(NSMaxX(drawingRect) - mBottomRightCornerRadius, NSMinY(drawingRect)) 
												  radius:mBottomRightCornerRadius];
	}
	else
	{
		[backgroundPath lineToPoint:NSMakePoint(NSMaxX(drawingRect), NSMinY(drawingRect))];
	}
	
	if(mBottomLeftCornerRadius)
	{
		[backgroundPath appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(drawingRect), NSMinY(drawingRect)) 
												 toPoint:NSMakePoint(NSMinX(drawingRect), NSMinY(drawingRect) + mBottomLeftCornerRadius) 
												  radius:mBottomLeftCornerRadius];
	}
	else
	{
		[backgroundPath lineToPoint:NSMakePoint(NSMinX(drawingRect), NSMinY(drawingRect))];
		[backgroundPath lineToPoint:NSMakePoint(NSMinX(drawingRect), NSMidY(drawingRect))];
	}
	
	[NSGraphicsContext saveGraphicsState];
	{
		[backgroundPath addClip];
		
		if(mBackgroundColor)
		{
			[mBackgroundColor set];
			[backgroundPath fill];
		}
		
        if(!mShouldDrawImageAboveGradient)
        {
            [self drawImageInBackgroundPath:backgroundPath withDrawingRect:drawingRect]; 
        }
		
        if([[self window] isMainWindow])
			[mForegroundGradient drawInRect:drawingRect angle:90.0];
		else
			[mBackgroundGradient drawInRect:drawingRect angle:90.0];
		
		if(mShouldDrawImageAboveGradient)
        {
            [self drawImageInBackgroundPath:backgroundPath withDrawingRect:drawingRect]; 
        }
		
		if(mHasTopLine)
		{
			if(mIsTopEtched)
			{
				[[NSColor colorWithDeviceWhite:0.0 alpha:0.2] set];
				[NSBezierPath fillRect:NSMakeRect(NSMinX(drawingRect), NSMaxY(drawingRect) - 1.0, 
												  NSWidth(drawingRect), 1.0)];
				
				[[NSColor colorWithDeviceWhite:1.0 alpha:0.25] set];
				[NSBezierPath fillRect:NSMakeRect(NSMinX(drawingRect), NSMaxY(drawingRect) - 2.0, 
												  NSWidth(drawingRect), 1.0)];
			}
			else
			{
				[[NSColor colorWithDeviceWhite:1.0 alpha:0.25] set];
				[NSBezierPath fillRect:NSMakeRect(NSMinX(drawingRect), NSMaxY(drawingRect) - 1.0, 
												  NSWidth(drawingRect), 1.0)];
			}
		}
		
		if(mHasBottomLine)
		{
			[[NSColor colorWithDeviceWhite:0.0 alpha:0.2] set];
			[NSBezierPath fillRect:NSMakeRect(NSMinX(drawingRect), NSMinY(drawingRect), 
											  NSWidth(drawingRect), 1.0)];
		}
		
		if(mInnerShadow)
		{
			[backgroundPath fillWithInnerShadow:mInnerShadow];
		}
	}
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark - Properties

@synthesize topRightCornerRadius = mTopRightCornerRadius;
- (void)setTopRightCornerRadius:(CGFloat)topRightCornerRadius
{
	mTopRightCornerRadius = topRightCornerRadius;
	[self setNeedsDisplay:YES];
}

@synthesize topLeftCornerRadius = mTopLeftCornerRadius;
- (void)setTopLeftCornerRadius:(CGFloat)topLeftCornerRadius
{
	mTopLeftCornerRadius = topLeftCornerRadius;
	[self setNeedsDisplay:YES];
}

@synthesize bottomRightCornerRadius = mBottomRightCornerRadius;
- (void)setBottomRightCornerRadius:(CGFloat)bottomRightCornerRadius
{
	mBottomRightCornerRadius = bottomRightCornerRadius;
	[self setNeedsDisplay:YES];
}

@synthesize bottomLeftCornerRadius = mBottomLeftCornerRadius;
- (void)setBottomLeftCornerRadius:(CGFloat)bottomLeftCornerRadius
{
	mBottomLeftCornerRadius = bottomLeftCornerRadius;
	[self setNeedsDisplay:YES];
}

#pragma mark -

@synthesize hasTopLine = mHasTopLine;
- (void)setHasTopLine:(BOOL)hasTopLine
{
	mHasTopLine = hasTopLine;
	[self setNeedsDisplay:YES];
}

@synthesize isTopEtched = mIsTopEtched;
- (void)setIsTopEtched:(BOOL)isTopEtched
{
	mIsTopEtched = isTopEtched;
	[self setNeedsDisplay:YES];
}

@synthesize hasBottomLine = mHasBottomLine;
- (void)setHasBottomLine:(BOOL)hasBottomLine
{
	mHasBottomLine = hasBottomLine;
	[self setNeedsDisplay:YES];
}

#pragma mark -

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
	if([backgroundColor isKindOfClass:[NSString class]])
		mBackgroundColor = RKStringToColor((NSString *)(backgroundColor));
	else
		mBackgroundColor = [backgroundColor copy];
	
	[self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor
{
	return [mBackgroundColor copy];
}

- (void)setForegroundGradient:(NSGradient *)foregroundGradient
{
	if([foregroundGradient isKindOfClass:[NSString class]])
		mForegroundGradient = RKStringToGradient((NSString *)(foregroundGradient));
	else
		mForegroundGradient = [foregroundGradient copy];
	
	[self setNeedsDisplay:YES];
}

- (NSGradient *)foregroundGradient
{
	return [mForegroundGradient copy];
}

- (void)setBackgroundGradient:(NSGradient *)backgroundGradient
{
	if([backgroundGradient isKindOfClass:[NSString class]])
		mBackgroundGradient = RKStringToGradient((NSString *)(backgroundGradient));
	else
		mBackgroundGradient = [backgroundGradient copy];
	
	[self setNeedsDisplay:YES];
}

- (NSGradient *)backgroundGradient
{
	return [mBackgroundGradient copy];
}

- (void)setInnerShadow:(NSShadow *)innerShadow
{
	mInnerShadow = [innerShadow copy];
	[self setNeedsDisplay:YES];
}

- (NSShadow *)innerShadow
{
	return [mInnerShadow copy];
}

#pragma mark -

- (void)setImage:(NSImage *)overlayImage
{
	if([overlayImage isKindOfClass:[NSString class]])
		overlayImage = [NSImage imageNamed:(NSString *)(overlayImage)];
	
	mImage = [overlayImage copy];
	[mImage setFlipped:[self isFlipped]];
	[self setNeedsDisplay:YES];
}

- (NSImage *)image
{
	return [mImage copy];
}

@synthesize imageShadow = mImageShadow;
- (void)setImageShadow:(NSShadow *)imageShadow
{
	mImageShadow = imageShadow;
	[self setNeedsDisplay:YES];
}

@synthesize imageHasReflection = mImageHasReflection;
- (void)setImageHasReflection:(BOOL)overlayImageHasReflection
{
	mImageHasReflection = overlayImageHasReflection;
	[self setNeedsDisplay:YES];
}

@synthesize shouldTileImage = mShouldTileImage;
- (void)setShouldTileImage:(BOOL)shouldTileOverlayImage
{
	mShouldTileImage = shouldTileOverlayImage;
	[self setNeedsDisplay:YES];
}

@synthesize shouldDrawImageAboveGradient = mShouldDrawImageAboveGradient;
- (void)setShouldDrawImageAboveGradient:(BOOL)shouldDrawImageAboveGradient
{
    mShouldDrawImageAboveGradient = shouldDrawImageAboveGradient;
	[self setNeedsDisplay:YES];
}

#pragma mark -

@synthesize delegate = mDelegate;

#pragma mark - Events

- (void)mouseExited:(NSEvent *)event
{
	if([mDelegate respondsToSelector:@selector(windowChromeViewMouseDidExit:)])
	{
		[mDelegate windowChromeViewMouseDidExit:self];
		return;
	}
	
	[super mouseExited:event];
}

- (void)mouseEntered:(NSEvent *)event
{
	if([mDelegate respondsToSelector:@selector(windowChromeViewMouseDidEnter:)])
	{
		[mDelegate windowChromeViewMouseDidEnter:self];
		return;
	}
	
	[super mouseEntered:event];
}

- (void)mouseUp:(NSEvent *)event
{
	if(([event clickCount] == 1) && [mDelegate respondsToSelector:@selector(windowChromeViewWasClicked:)])
		return [mDelegate windowChromeViewWasClicked:self];
	
	[super mouseUp:event];
}

- (void)keyDown:(NSEvent *)event
{
	if([mDelegate respondsToSelector:@selector(windowChromeView:handleKeyPress:)])
	{
		if([mDelegate windowChromeView:self handleKeyPress:event])
			return;
	}
	
	[super keyDown:event];
}

#pragma mark - Drop Destination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if([mDelegate respondsToSelector:@selector(windowChromeView:validateDrop:)])
		return [mDelegate windowChromeView:self validateDrop:sender];
	
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if([mDelegate respondsToSelector:@selector(windowChromeView:validateDrop:)])
		return [mDelegate windowChromeView:self validateDrop:sender];
	
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return (mDelegate != nil);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if([mDelegate respondsToSelector:@selector(windowChromeView:acceptDrop:)])
		return [mDelegate windowChromeView:self acceptDrop:sender];
	
	return NO;
}

@end
