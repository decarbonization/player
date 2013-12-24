//
//  RKBrowserScrollView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/26/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

RK_EXTERN NSString *const RKBrowserScrollViewDidScrollToTopNotification;
RK_EXTERN NSString *const RKBrowserScrollViewDidScrollToBottomNotification;

@interface RKBrowserScrollView : NSScrollView
{
	NSSize mDocumentViewSizeAtTimeOfLastBeginningNotification;
	NSSize mDocumentViewSizeAtTimeOfLastEndNotification;
	
	BOOL mHasSentBeginningNotification;
	BOOL mHasSentEndNotification;
}

@end
