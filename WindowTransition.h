//
//  WindowTransition.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/28/11.
//  Copyright (c) 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

///The WindowTransition class encapsulates the transition used between windows in Pinna.
@interface WindowTransition : NSObject
{
	NSWindow *mTransitionWindow;
	
	NSView *mTransitionHostView;
	
	CALayer *mTransitionLayer;
	
	NSWindow *mSourceWindow;
	NSWindow *mTargetWindow;
}

///Initialize the receiver with specified source and target windows.
- (id)initWithSourceWindow:(NSWindow *)sourceWindow targetWindow:(NSWindow *)targetWindow;

#pragma mark - Properties

///The source window
@property (nonatomic, readonly) NSWindow *sourceWindow;

///The target window
@property (nonatomic, readonly) NSWindow *targetWindow;

#pragma mark - Transitioning

///Run the transition with a specified (optional) completion handler block.
- (void)transition:(void(^)())completionHandler;

@end
