//
//  ScrubbingBarView.h
//  Pinna
//
//  Created by Peter MacWhinnie on 1/21/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The scrubbing bar view provides the interface for moving within songs in Pinna's UI.
@interface ScrubbingBarView : NSView
{
	/** Internal State **/
	
	CGFloat mTimeStampWidth;
	NSString *mTimeStampDisplayString;
	NSSize mTimeStampDisplayStringSize;
	
	/** Properties **/
	
	NSTimeInterval mDuration;
	NSTimeInterval mCurrentTime;
	dispatch_block_t mAction;
	BOOL mUseTimeRemainingDisplayStyle;
}

#pragma mark Properties

///The duration.
@property (nonatomic) NSTimeInterval duration;

///The current time.
@property (nonatomic) NSTimeInterval currentTime;

#pragma mark -

///Whether or not the scrubbing bar should display
///remaining time in its time stamp area.
@property (nonatomic) BOOL useTimeRemainingDisplayStyle;

#pragma mark -

///The action block.
@property (nonatomic, copy) dispatch_block_t action;

@end
