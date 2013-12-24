//
//  RKAnimator.m
//  RoundaboutKitMac
//
//  Created by Kevin MacWhinnie on 8/14/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "RKAnimator.h"

@implementation RKAnimatorTransaction {
	NSMutableArray *_animations;
}

- (id)init
{
	if((self = [super init])) {
		_animations = [NSMutableArray new];
		_duration = 0.25;
		_animationCurve = NSAnimationEaseInOut;
	}
    
	return self;
}

#pragma mark - Animations

- (void)fadeOutTarget:(id)target
{
	NSParameterAssert(target);
    
	[_animations addObject:@{
        NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect,
        NSViewAnimationTargetKey: target,
    }];
}

- (void)fadeInTarget:(id)target
{
	NSParameterAssert(target);
    
	[_animations addObject:@{
        NSViewAnimationEffectKey: NSViewAnimationFadeInEffect,
        NSViewAnimationTargetKey: target,
    }];
}

- (void)setFrame:(NSRect)frame forTarget:(id)target
{
	NSParameterAssert(target);
    
	[_animations addObject:@{
        NSViewAnimationEndFrameKey: [NSValue valueWithRect:frame],
        NSViewAnimationTargetKey: target,
    }];
}

@end

#pragma mark -

@implementation RKAnimator {
	NSMapTable *_activeAnimationTargets;
}

+ (RKAnimator *)animator
{
    static RKAnimator *animator = nil;
	static dispatch_once_t predicate = 0;
	dispatch_once(&predicate, ^{
		animator = [RKAnimator new];
	});
	
	return animator;
}

#pragma mark - Internal Gunk

- (id)init
{
	if((self = [super init])) {
		_activeAnimationTargets = [NSMapTable mapTableWithStrongToStrongObjects];
	}
    
	return self;
}

#pragma mark - Animating

- (void)animationDidEnd:(NSViewAnimation *)viewAnimation
{
	NSArray *animations = [viewAnimation viewAnimations];
	for (id target in [animations valueForKey:NSViewAnimationTargetKey])
		[_activeAnimationTargets removeObjectForKey:target];
	
	RKAnimationCompletionHandler completionHandler = [viewAnimation associatedValueForKey:@"completionHandler"];
	if(completionHandler)
		completionHandler(YES);
}

- (void)animationDidStop:(NSViewAnimation *)viewAnimation
{
	NSArray *animations = [viewAnimation viewAnimations];
	for (id target in [animations valueForKey:NSViewAnimationTargetKey])
		[_activeAnimationTargets removeObjectForKey:target];
	
	RKAnimationCompletionHandler completionHandler = [viewAnimation associatedValueForKey:@"completionHandler"];
	if(completionHandler)
		completionHandler(NO);
}

#pragma mark - Utilities

- (BOOL)isAnimating:(id)target
{
	return ([_activeAnimationTargets objectForKey:target] != nil);
}

- (void)terminateAnimationsRelatedToTargets:(NSArray *)targets
{
	for (id target in targets) {
		NSViewAnimation *activeAnimation = [_activeAnimationTargets objectForKey:target];
		[activeAnimation stopAnimation];
		
		[_activeAnimationTargets removeObjectForKey:target];
	}
}

#pragma mark - Transactions

- (void)transaction:(void(^)(RKAnimatorTransaction *transaction))block
{
	[self transaction:block completionHandler:nil];
}

- (void)transaction:(void(^)(RKAnimatorTransaction *transaction))block completionHandler:(RKAnimationCompletionHandler)completionHandler
{
    NSParameterAssert(block);
	
	RKAnimatorTransaction *transaction = [self beginTransaction];
    transaction.completionHandler = completionHandler;
	block(transaction);
	[self commitTransaction:transaction synchronously:NO];
}

- (void)synchronousTransaction:(void(^)(RKAnimatorTransaction *transaction))block
{
	NSParameterAssert(block);
	
	RKAnimatorTransaction *transaction = [self beginTransaction];
	block(transaction);
	[self commitTransaction:transaction synchronously:YES];
}

#pragma mark -

- (RKAnimatorTransaction *)beginTransaction
{
	RKAnimatorTransaction *transaction = [RKAnimatorTransaction new];
	return transaction;
}

- (void)commitTransaction:(RKAnimatorTransaction *)transaction synchronously:(BOOL)synchronously
{
	NSParameterAssert(transaction);
	
	NSArray *animations = transaction.animations;
	NSViewAnimation *viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
	[viewAnimation setAssociatedValue:transaction.completionHandler forKey:@"completionHandler"];
	[viewAnimation setDuration:transaction.duration];
	[viewAnimation setAnimationCurve:transaction.animationCurve];
	[viewAnimation setDelegate:self];
    
    if(synchronously)
        [viewAnimation setAnimationBlockingMode:NSAnimationBlocking];
	
	for (id target in [animations valueForKey:NSViewAnimationTargetKey]) {
		NSViewAnimation *activeAnimation = [_activeAnimationTargets objectForKey:target];
		[activeAnimation stopAnimation];
		
		[_activeAnimationTargets setObject:viewAnimation forKey:target];
	}
	
	[viewAnimation startAnimation];
}

@end
