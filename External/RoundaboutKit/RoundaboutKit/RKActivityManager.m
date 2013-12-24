//
//  RKActivityManager.m
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 12/10/12.
//  Copyright (c) 2012 Kevin MacWhinnie. All rights reserved.
//

#import "RKActivityManager.h"
#if TARGET_OS_IPHONE
#   import <UIKit/UIKit.h>
#endif /* TARGET_OS_IPHONE */

@implementation RKActivityManager

+ (instancetype)sharedActivityManager
{
    static RKActivityManager *sharedActivityManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedActivityManager = [self new];
    });
    
    return sharedActivityManager;
}

- (id)init
{
    if((self = [super init])) {
        [self addObserver:self forKeyPath:@"activityCount" options:0 context:NULL];
    }
    
    return self;
}

#pragma mark - Observations

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if((object == self) && [keyPath isEqualToString:@"activityCount"]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self willChangeValueForKey:@"isActive"];
#if TARGET_OS_IPHONE
            if(_updatesNetworkActivityIndicator)
                [UIApplication sharedApplication].networkActivityIndicatorVisible = self.isActive;
#endif /* TARGET_OS_IPHONE */
            [self didChangeValueForKey:@"isActive"];
        }];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Properties

- (BOOL)isActive
{
    return (self.activityCount > 0);
}

#pragma mark - Activity

- (void)incrementActivityCount
{
    if(self.activityCount == NSIntegerMax)
        [NSException raise:NSInternalInconsistencyException format:@"NSIntegerMax reached, cannot increment activity count anymore."];
    
    self.activityCount++;
}

- (void)decrementActivityCount
{
    if(self.activityCount == 0)
        return;
    
    self.activityCount--;
}

@end
