//
//  PinnaApplication.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#import "PlayerApplication.h"

@implementation PlayerApplication

- (void)addImportantQueue:(NSOperationQueue *)queue
{
	NSMutableArray *importantQueues = [self associatedValueForKey:@"importantQueues"];
	if(!importantQueues)
	{
		importantQueues = [NSMutableArray array];
		[self setAssociatedValue:importantQueues forKey:@"importantQueues"];
	}
	
	[importantQueues addObject:queue];
}

- (void)removeImportantQueue:(NSOperationQueue *)queue
{
	NSMutableArray *importantQueues = [self associatedValueForKey:@"importantQueues"];
	[importantQueues removeObject:queue];
}

- (NSArray *)importantQueues
{
	return [[self associatedValueForKey:@"importantQueues"] copy] ?: [NSArray array];
}

#pragma mark -

- (BOOL)isWaitingForImportantQueuesToFinish
{
	return mIsWaitingForImportantQueuesToFinish;
}

- (void)waitForImportantQueuesToFinish
{
	mIsWaitingForImportantQueuesToFinish = YES;
	
	NSArray *importantQueues = [self importantQueues];
	for (NSOperationQueue *importantQueue in importantQueues)
	{
		[importantQueue cancelAllOperations];
		[importantQueue waitUntilAllOperationsAreFinished];
	}
}

#pragma mark - JSTalk

///Derived from <https://github.com/ccgus/jstalk/blob/master/src/JSTListener.m>
- (void)broadcastToJSTalkWithRootObject:(id)object
{
    if(mJSTalkBroadcastConnection || !object || RKProcessIsRunningInDebugger())
        return;
    
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	
	NSString *name = [NSString stringWithFormat:@"%@.JSTalk", bundleIdentifier];
	
	mJSTalkBroadcastConnection = [NSConnection new];
	[mJSTalkBroadcastConnection setIndependentConversationQueueing:YES];
    mJSTalkObject = object;
	[mJSTalkBroadcastConnection setRootObject:mJSTalkObject];
	
	if(![mJSTalkBroadcastConnection registerName:name])
	{
		NSLog(@"JSTalk could not broadcast with name %@", name);
	}
}

- (void)stopBroadcastingToJSTalk
{
    [mJSTalkBroadcastConnection invalidate];
    mJSTalkBroadcastConnection = nil;
}

@end
