//
//  ExFMTrendingSourceController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/17/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ExFMTrendingSourceController : NSWindowController
{
	IBOutlet NSArrayController *oContentController;
}

#pragma mark Showing/Hiding

- (void)showBelowView:(NSView *)view;

- (void)hide;

@end
