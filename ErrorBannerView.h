//
//  ErrorPresentationView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 10/12/12.
//
//

#import <Cocoa/Cocoa.h>

@class ErrorPresentationViewController;

///The view responsible for presenting error banners in the main window.
@interface ErrorBannerView : NSView
{
	ErrorPresentationViewController *mErrorPresentationViewController;
	NSTimer *mCloseTimer;
	
	/** Properties **/
	
	NSString *mTitle;
	NSString *mButtonTitle;
	dispatch_block_t mButtonAction;
}

#pragma mark - Properties

///The title of the error presentation view.
@property (copy) NSString *title;

///The title of the informative button showne below the title.
@property (copy) NSString *buttonTitle;

///The block to invoke upon the informative button being clicked.
@property (copy) dispatch_block_t buttonAction;

#pragma mark -

///Whether or not the error presentation view is visible.
@property (nonatomic, readonly) BOOL isVisible;

#pragma mark - Presentation

///Shows the receiver in a specified parent view.
///
///Invoking this method will add the receiver to the specified view,
///slide the error down from the top, and then fade out the error
///after a predetermined number of seconds.
- (void)showInView:(NSView *)parentView;

///Fades out the receiver and removes it from its parent view.
- (void)close;

@end
