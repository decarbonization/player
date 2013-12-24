//
//  RKChromeView.h
//  Pinna
//
//  Created by Peter MacWhinnie on 12/6/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol RKChromeViewDelegate;

///The RKChromeView class is responsible for providing all of
///the custom window chrome used in Player's interface.
@interface RKChromeView : NSView
{
	/** State **/
	NSTrackingRectTag mTrackingArea;
	
	/** Properties **/
	
	CGFloat mTopLeftCornerRadius;
	CGFloat mTopRightCornerRadius;
	CGFloat mBottomLeftCornerRadius;
	CGFloat mBottomRightCornerRadius;
	
	BOOL mHasTopLine;
	BOOL mIsTopEtched;
	BOOL mHasBottomLine;
	
	NSColor *mBackgroundColor;
	NSGradient *mForegroundGradient;
	NSGradient *mBackgroundGradient;
	NSShadow *mInnerShadow;
	
	NSImage *mImage;
	NSShadow *mImageShadow;
	BOOL mImageHasReflection;
	BOOL mShouldTileImage;
    BOOL mShouldDrawImageAboveGradient;
	
	__unsafe_unretained id <RKChromeViewDelegate> mDelegate;
}

#pragma mark Properties

///The top left corner radius. Default value is 0.0.
@property (nonatomic) CGFloat topLeftCornerRadius;

///The top right corner radius. Default value is 0.0.
@property (nonatomic) CGFloat topRightCornerRadius;

///The bottom left corner radius. Default value is 0.0.
@property (nonatomic) CGFloat bottomLeftCornerRadius;

///The bottom right corner radius. Default value is 0.0.
@property (nonatomic) CGFloat bottomRightCornerRadius;

#pragma mark -

///Whether or not a line should be draw on the top of the view.
@property (nonatomic) BOOL hasTopLine;

///Whether or not a dark line followed by a light line should be
///drawn on the top of the view. Only honoured if `hasTopLine` is true.
@property (nonatomic) BOOL isTopEtched;

///Whether or not a line should be drawn on the bottom of the view.
@property (nonatomic) BOOL hasBottomLine;

#pragma mark -

///The color drawn behind the view's gradients (if any). Default value is nil.
@property (nonatomic, copy) NSColor *backgroundColor;

///The gradient used as a background when the chrome view's window is key.
///A string may be passed in place of an instance of NSGradient. \see(BKMakeRKStringToGradient)
@property (nonatomic, copy) NSGradient *foregroundGradient;

///The gradient used as a background when the chrome view's window is not key.
///A string may be passed in place of an instance of NSGradient. \see(BKMakeRKStringToGradient)
@property (nonatomic, copy) NSGradient *backgroundGradient;

///The shadow drawn on the inside of the chrome view.
@property (nonatomic, copy) NSShadow *innerShadow;

#pragma mark -

///The image to overlay on top of the chrome. Displayed proportionally. Optional.
///A string may be passed in place of an instance of NSImage. \see(+[NSImage imageNamed:])
@property (nonatomic, copy) NSImage *image;

///The shadow to draw behind the image, if any.
///
///The image shadow is only drawn if there is no reflection,
///and the image is not being tiled.
@property (nonatomic, copy) NSShadow *imageShadow;

///Whether or not the overlay image has a reflection. Only applies if the image is not tiled.
@property (nonatomic) BOOL imageHasReflection;

///Whether or not the overlay image should be tiled. Default is NO.
@property (nonatomic) BOOL shouldTileImage;

///Whether or not the image should be drawn above the gradient. Default value is YES.
@property (nonatomic) BOOL shouldDrawImageAboveGradient;

#pragma mark -

///The delegate of the chrome view.
@property (nonatomic, assign) IBOutlet id <RKChromeViewDelegate> delegate;

@end

#pragma mark -

@protocol RKChromeViewDelegate <NSObject>
@optional

///Invoked when an item is being dragged over a chrome view.
- (NSDragOperation)windowChromeView:(RKChromeView *)windowChromeView validateDrop:(id <NSDraggingInfo>)info;

///Invoked when an item has been dropped on a chrome view.
- (BOOL)windowChromeView:(RKChromeView *)windowChromeView acceptDrop:(id <NSDraggingInfo>)info;

#pragma mark -

///Invoked when a chrome view has been clicked.
- (void)windowChromeViewWasClicked:(RKChromeView *)windowChromeView;

#pragma mark -

///Invoked when a key press is propagated up to a chrome view.
- (BOOL)windowChromeView:(RKChromeView *)windowChromeView handleKeyPress:(NSEvent *)event;

///Invoked when the mouse enters a given chrome view.
- (void)windowChromeViewMouseDidEnter:(RKChromeView *)windowChromeView;

///Invoked when the mouse exits a given chrome view.
- (void)windowChromeViewMouseDidExit:(RKChromeView *)windowChromeView;

@end
