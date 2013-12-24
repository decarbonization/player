//
//  RKAnimator.h
//  RoundaboutKitMac
//
//  Created by Kevin MacWhinnie on 8/14/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The completion handler block of the RKAnimator class.
typedef void(^RKAnimationCompletionHandler)(BOOL didFinish);

#pragma mark -

///The RKAnimatorTransaction class encapsulates a write-only
///collection of animations to be run by the RKAnimator class.
@interface RKAnimatorTransaction : NSObject

#pragma mark Properties

///The animations of the transaction.
@property (nonatomic, readonly, copy) NSArray *animations;

#pragma mark -

///The duration of the animation.
@property (nonatomic) NSTimeInterval duration;

///The curve of the animation.
@property (nonatomic) NSAnimationCurve animationCurve;

///The block to invoke when the animation has completed.
@property (nonatomic, copy) RKAnimationCompletionHandler completionHandler;

#pragma mark - Animations

///Fade out a target.
///
///	\param	target	An NSWindow or NSView to animate.
- (void)fadeOutTarget:(id)target;

///Fade in a target.
///
///	\param	target	An NSWindow or NSView to animate.
- (void)fadeInTarget:(id)target;

///Set the frame of a target.
///
///	\param	frame	The frame to set to.
///	\param	target	An NSWindow or NSView.
- (void)setFrame:(NSRect)frame forTarget:(id)target;

@end

#pragma mark -

///The RKAnimator class encapsulates the NSViewAnimation mechanism
///to provide sane defaults and a cleaner interface.
@interface RKAnimator : NSObject <NSAnimationDelegate>

///Returns the default animator object, creating it if it doesn't exist.
+ (RKAnimator *)animator;

#pragma mark - Utilities

///Returns a boolean indicating whether or not a target is being animated.
- (BOOL)isAnimating:(id)target;

///Terminates all active animations related to a specified array of targets
- (void)terminateAnimationsRelatedToTargets:(NSArray *)targets;

#pragma mark - Transactions

///Create a transaction, pass it to a block, then run it.
- (void)transaction:(void(^)(RKAnimatorTransaction *transaction))block;

///Create a transaction, pass it to a block, then run it.
- (void)transaction:(void(^)(RKAnimatorTransaction *transaction))block completionHandler:(RKAnimationCompletionHandler)completionHandler;

///Create a transaction, pass it to a block, then run it synchronously.
- (void)synchronousTransaction:(void(^)(RKAnimatorTransaction *transaction))block;

#pragma mark -

///Returns a new transaction that you may operate on.
///
///If you do not wish to use a transaction, you may simply discard it.
- (RKAnimatorTransaction *)beginTransaction;

///Commit a transaction to be animated.
- (void)commitTransaction:(RKAnimatorTransaction *)transaction synchronously:(BOOL)synchronously;

@end
