//
//  RKNavigationOverlayView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/7/13.
//
//

#import "RKView.h"

@class RKNavigationController;

///The RKSideSheetView class encapsulates a sheet-style view which is displayed
///over a specified content view. The sheet's contents are shown to the right of
///the view over a semi-translucent white background.
///
///Content is specified by modifying the side sheet's navigation controller.
@interface RKSideSheetView : RKView

///The navigation controller the overlay manages.
@property (nonatomic, readonly) RKNavigationController *navigationController;

#pragma mark -

///The view displayed behind the sheet's content view.
@property (nonatomic) RKView *backgroundView;

#pragma mark -

///The width of the content.
///
///Defaults to 320 points.
@property (nonatomic) CGFloat contentWidth;

///The block to invoke when the sheet is dismissed.
@property (nonatomic, copy) void(^dismissalHandler)(RKSideSheetView *sheet);

#pragma mark - Showing/Hiding The Overlay

///Shows the overlay in a specified view.
- (void)showInView:(NSView *)view animated:(BOOL)animated completionHandler:(dispatch_block_t)completionHandler;

///Dismisses the overlay.
- (void)dismiss:(BOOL)animated completionHandler:(dispatch_block_t)completionHandler;

@end
