//
//	This code is derived from RSVerticallyCenteredTextFieldCell and IconTextFieldCell.
//
//	Copyright 2006 Red Sweater Software. All rights reserved.
//	Copyright 2008 Brian Amerige. All rights reserved.
//

#import "RKBrowserIconTextFieldCell.h" 

@implementation RKBrowserIconTextFieldCell

#pragma mark Properties

@synthesize image = mImage;
@synthesize stylizesImage = mStylizesImage;
@synthesize imageInset = mImageInset;
@synthesize spacingBetweenImageAndText = mSpacingBetweenImageAndText;

#pragma mark -

@synthesize backgroundGradient = mBackgroundGradient;
@synthesize buttonImage = mButtonImage;

#pragma mark - NSCopying

- (id)initWithCoder:(NSCoder *)decoder
{
	if((self = [super initWithCoder:decoder]))
	{
		mImageInset = 0.0;
		mSpacingBetweenImageAndText = 5.0;
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone 
{
	//Note that we must use copyWithZone, here, otherwise we lose attributes.
    RKBrowserIconTextFieldCell *cellCopy = [super copyWithZone:zone];
	
	//Rather annoyingly, NSActionCell's copyWithZone: implementation doesn't initalize instance variables to nil. So calling setImage: on cellCopy would actually release mImage, thus crashing.
	cellCopy->mImage = mImage;
	cellCopy->mStylizesImage = mStylizesImage;
	cellCopy->mImageInset = mImageInset;
	cellCopy->mSpacingBetweenImageAndText = mSpacingBetweenImageAndText;
	
	cellCopy->mBackgroundGradient = [mBackgroundGradient copy];
	cellCopy->mButtonImage = mButtonImage;
	
    return cellCopy;
}

#pragma mark - NSCell Overrides

- (void)endEditing:(NSText *)textObj
{
    mIsEditingOrSelecting = NO;
    [super endEditing:textObj];
}

#pragma mark -

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
	if(mBackgroundGradient)
	{
		[mBackgroundGradient drawInRect:cellFrame angle:90.0];
		
		NSColor *lastColor = nil;
		[mBackgroundGradient getColor:&lastColor location:NULL atIndex:0];
		
		[lastColor set];
		[NSBezierPath fillRect:NSMakeRect(0.0, NSMinY(cellFrame), NSWidth(cellFrame), 1.0)];
        [NSBezierPath fillRect:NSMakeRect(0.0, NSMaxY(cellFrame) - 1.0, NSWidth(cellFrame), 1.0)];
	}
	
    if(mIsEditingOrSelecting)
        return;
    
	cellFrame = NSInsetRect(cellFrame, mSpacingBetweenImageAndText, 0.0);
	
    if(mImage)
	{
		NSRect imageFrame;
		NSDivideRect(cellFrame, 
					 &imageFrame, 
					 &cellFrame,
					 mImageInset + mSpacingBetweenImageAndText + [mImage size].width,
					 NSMinXEdge);
		
        if ([self drawsBackground])
		{
			[NSGraphicsContext saveGraphicsState];
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
			[NSGraphicsContext restoreGraphicsState];
        }
		
        imageFrame.origin.x += mImageInset;
        imageFrame.size = [mImage size];
		
        if ([controlView isFlipped])
            imageFrame.origin.y += floor((cellFrame.size.height / 2.0) - (imageFrame.size.height / 2.0));
        else
            imageFrame.origin.y -= floor((cellFrame.size.height / 2.0) - (imageFrame.size.height / 2.0));
		
		[NSGraphicsContext saveGraphicsState];
		{
			if(mStylizesImage)
			{
				NSBezierPath *imageAreaPath = [NSBezierPath bezierPathWithRoundedRect:imageFrame xRadius:2.0 yRadius:2.0];
				
				[RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.4], 0.0, NSMakeSize(0.0, -1.0)) set];
				[[NSColor whiteColor] set];
				[imageAreaPath fill];
				
				[imageAreaPath addClip];
				
				[mImage setFlipped:[controlView isFlipped]];
				[mImage drawInRect:imageFrame
						  fromRect:NSZeroRect
						 operation:NSCompositeSourceOver
						  fraction:1.0];
				
				[[NSColor clearColor] set];
				[imageAreaPath fillWithInnerShadow:RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.49], 4.0, NSMakeSize(0.0, -1.0))];
				
				[[NSColor colorWithDeviceWhite:0.0 alpha:0.1] set];
				[imageAreaPath strokeInside];
			}
			else
			{
				[mImage setFlipped:[controlView isFlipped]];
				[mImage drawInRect:imageFrame
						  fromRect:NSZeroRect
						 operation:NSCompositeSourceOver
						  fraction:1.0];
			}
		}
		[NSGraphicsContext restoreGraphicsState];
    }
	
	if(mButtonImage)
	{
		NSRect buttonImageRect = cellFrame;
		buttonImageRect.size = [mButtonImage size];
		
		buttonImageRect.origin.x = NSMaxX(cellFrame) - NSWidth(buttonImageRect);
		
		if([controlView isFlipped])
            buttonImageRect.origin.y += floor((NSHeight(cellFrame) / 2.0) - (buttonImageRect.size.height / 2.0));
        else
            buttonImageRect.origin.y -= floor((NSHeight(cellFrame) / 2.0) - (buttonImageRect.size.height / 2.0));
		
		[mButtonImage setFlipped:[controlView isFlipped]];
		[mButtonImage drawInRect:buttonImageRect
				  fromRect:NSZeroRect
				 operation:NSCompositeSourceOver
				  fraction:1.0];
		
		cellFrame.size.width -= NSWidth(buttonImageRect);
	}
	
    [super drawWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (mImage ? [mImage size].width : 0) + mImageInset + mSpacingBetweenImageAndText;
    return cellSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSSize contentSize = [self cellSize];
	cellFrame.origin.y += (cellFrame.size.height - contentSize.height) / 2.0;
    cellFrame.size.height = contentSize.height;
	
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

#pragma mark - NSTextFieldCell Overrides

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
	// Get the parent's idea of where we should draw
	NSRect newRect = [super drawingRectForBounds:theRect];
	
	// When the text field is being 
	// edited or selected, we have to turn off the magic because it screws up 
	// the configuration of the field editor.  We sneak around this by 
	// intercepting selectWithFrame and editWithFrame and sneaking a 
	// reduced, centered rect in at the last minute.
	if(!mIsEditingOrSelecting)
	{
		// Get our ideal size for current text
		NSSize textSize = [self cellSizeForBounds:theRect];
		
		// Center that in the proposed rect
		float heightDelta = newRect.size.height - textSize.height;	
		if (heightDelta > 0)
		{
			newRect.size.height -= heightDelta;
			newRect.origin.y += (heightDelta / 2);
		}
	}
	
	return newRect;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	aRect = [self drawingRectForBounds:aRect];
    CGFloat widthDelta = mImage.size.width + mImageInset + mSpacingBetweenImageAndText + 10.0;
    aRect.origin.x += widthDelta;
    aRect.size.width -= widthDelta + mButtonImage.size.width + 10.0;
	
    mIsEditingOrSelecting = YES;
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
    
    [textObj setFont:[self font]];
    [textObj setTextColor:[NSColor blackColor]];
    [textObj setBackgroundColor:[NSColor whiteColor]];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
	aRect = [self drawingRectForBounds:aRect];
    CGFloat widthDelta = mImage.size.width + mImageInset + mSpacingBetweenImageAndText + 10.0;
    aRect.origin.x += widthDelta;
    aRect.size.width -= widthDelta + mButtonImage.size.width + 10.0;
	
    mIsEditingOrSelecting = YES;
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
    
    [textObj setFont:[self font]];
    [textObj setTextColor:[NSColor blackColor]];
    [textObj setBackgroundColor:[NSColor whiteColor]];
}

@end
