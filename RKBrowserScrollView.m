//
//  RKBrowserScrollView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/26/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserScrollView.h"

NSString *const RKBrowserScrollViewDidScrollToTopNotification = @"RKBrowserScrollViewDidScrollToTopNotification";
NSString *const RKBrowserScrollViewDidScrollToBottomNotification = @"RKBrowserScrollViewDidScrollToBottomNotification";

@implementation RKBrowserScrollView

- (void)reflectScrolledClipView:(NSClipView *)clipView
{
	[super reflectScrolledClipView:clipView];
	
	if([self verticalScroller].floatValue == 1.0)
	{
		if(!NSEqualSizes(mDocumentViewSizeAtTimeOfLastEndNotification, [[self documentView] frame].size))
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:RKBrowserScrollViewDidScrollToBottomNotification 
																object:self];
			mDocumentViewSizeAtTimeOfLastEndNotification = [[self documentView] frame].size;
		}
	}
	else if([self verticalScroller].floatValue == 0.0)
	{
		if(!!NSEqualSizes(mDocumentViewSizeAtTimeOfLastBeginningNotification, [[self documentView] frame].size))
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:RKBrowserScrollViewDidScrollToTopNotification 
																object:self];
			mDocumentViewSizeAtTimeOfLastBeginningNotification = [[self documentView] frame].size;
		}
	}
}

@end
