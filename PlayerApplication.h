//
//  PinnaApplication.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/21/13.
//
//

#import <Cocoa/Cocoa.h>

///The PlayerApplication class adds several mechanisms to NSApplication including
///an "important queue" mechanism which is used to track queues that must be allowed
///to finish in order for the application to terminate gracefully, as well as
///a JSTalk-enabling mechanism. Additionally, `PinnaApplication` adds hooks so that
///`WindowTransition` can function correctly when an application is hidden.
@interface PlayerApplication : NSApplication
{
    BOOL mIsWaitingForImportantQueuesToFinish;
    id mJSTalkObject;
    NSConnection *mJSTalkBroadcastConnection;
}

///Adds a queue to the receiver's list of queues that must be allowed to finish before an application can terminate.
- (void)addImportantQueue:(NSOperationQueue *)queue;

///Removes a queue from the receiver's list of queues that must be allowed to finish before an application can terminate.
- (void)removeImportantQueue:(NSOperationQueue *)queue;

///Returns the queues that must be allowed to finish before an application can terminate.
- (NSArray *)importantQueues;

#pragma mark -

///Indicates whether or not the application is waiting for important queues to finish.
@property (readonly) BOOL isWaitingForImportantQueuesToFinish;

///Cancels all pending operations on the receiver's important queues and waits for them to
///finish. This method blocks the calling thread until all remaining operations have completed.
- (void)waitForImportantQueuesToFinish;

#pragma mark - JSTalk

///Causes the receiver to broadcast the presence of the app with a specified root object.
- (void)broadcastToJSTalkWithRootObject:(id)object;

///Causes the receiver to stop broadcasting through JSTalk.
- (void)stopBroadcastingToJSTalk;

@end
