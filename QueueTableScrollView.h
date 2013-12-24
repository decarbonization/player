//
//  QueueTableScrollView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/4/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QueueTableScrollView : NSScrollView
{
	///The tracking area used to highlight rows.
	NSTrackingArea *mHoverTrackingArea;
}

@end
