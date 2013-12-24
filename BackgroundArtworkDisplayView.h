//
//  BackgroundArtworkDisplayView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/27/11.
//  Copyright (c) 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BackgroundArtworkDisplayView : NSView
{
	BOOL mIsMouseInView;
	
	/** Properties **/
	
	///The storage for `mImage`
	NSImage *mImage;
}

#pragma mark Properties

@property (nonatomic, copy) NSImage *image;

@property (nonatomic, readonly) BOOL isMouseInView;

@end
