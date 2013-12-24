//
//  HeaderLabelView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/25/11.
//  Copyright (c) 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AMIndeterminateProgressIndicatorCell;
@interface HeaderLabelView : NSView
{
	/** Internal **/
	
	///The spinner of the header.
	AMIndeterminateProgressIndicatorCell *mSpinner;
	
	///The animation timer of the spinner.
	NSTimer *mSpinnerHeartBeat;
	
	///The tracking area used to highlight rows.
	NSTrackingArea *mHoverTrackingArea;
	
	///Whether or not a mouse down can move the window.
	BOOL mMouseDownCanMoveWindow;
	
	///Whether or not the mouse is inside the header view.
	BOOL mMouseInside;
	
	///Whether or not the mouse is pressed.
	BOOL mMouseIsPressed;
	
	///Whether or not the header view is highlighted.
	BOOL mHighlighted;
	
	
	/** Properties **/
	
	///Storage for `string`
	NSString *mString;
	
	///Storage for `leftMargin`
	CGFloat mLeftMargin;
	
	///Storage for `rightMargin`
	CGFloat mRightMargin;
	
	///Storage for `showBusyIndicator`
	BOOL mShowBusyIndicator;
	
	
	///Storage for `clickable`
	BOOL mClickable;
	
	///Storage for `action`
	SEL mAction;
	
	///Storage for `target`
	id mTarget;
}

#pragma mark Properties

///The string value of the header label view.
@property (nonatomic, copy) NSString *string;

///The left margin of the header label view.
@property (nonatomic) CGFloat leftMargin;

///The right margin of the header label view.
@property (nonatomic) CGFloat rightMargin;

///Whether or not the header should be spinning its progress indicator.
@property (nonatomic) BOOL showBusyIndicator;

#pragma mark -

///Whether or not the view is clickable.
@property (nonatomic) BOOL clickable;

///The view's action.
@property (nonatomic) SEL action;

///The target of the view's action.
@property (nonatomic) id target;

@end
