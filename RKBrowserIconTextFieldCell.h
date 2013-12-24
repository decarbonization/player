//
//	This code is derived from RSVerticallyCenteredTextFieldCell and IconTextFieldCell.
//
//	Copyright 2006 Red Sweater Software. All rights reserved.
//	Copyright 2008 Brian Amerige. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The cell used by RKBrowser.
@interface RKBrowserIconTextFieldCell : NSTextFieldCell
{
    NSImage	*mImage;
	BOOL mStylizesImage;
	CGFloat mImageInset;
	CGFloat mSpacingBetweenImageAndText;
	
	NSGradient *mBackgroundGradient;
	NSImage *mButtonImage;
	
	BOOL mIsEditingOrSelecting;
}

///The image of the cell.
@property (readwrite, retain) NSImage *image;

///Whether or not the image of the cell should be stylized.
@property (nonatomic) BOOL stylizesImage;

///The left inset of the image. Default value 0.0.
@property (nonatomic) CGFloat imageInset;

///The spacing between the cell's image and text. Default value 5.0.
@property (nonatomic) CGFloat spacingBetweenImageAndText;

#pragma mark -

///The background gradient of the cell. Used to indicate now playing in the queue.
@property (nonatomic, copy) NSGradient *backgroundGradient;

///The button image of the cell.
@property (retain) NSImage *buttonImage;

@end