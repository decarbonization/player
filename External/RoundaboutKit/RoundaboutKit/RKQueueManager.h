//
//  RKQueueManager.h
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 6/13/13.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

///The RKQueueManager class manages a collection of named queues which tasks can be executed on.
@interface RKQueueManager : NSObject

///Returns the shared queue cache, creating it if it does not already exist.
+ (NSCache *)queueCache;

///Returns a queue matching a given name.
///
/// \param  queueName   The name of the queue to find. Required.
///
/// \result A queue corresponding to the name given.
///
///This method may return different values if called concurrently
///from multiple threads. The returned queue may not be reconfigured.
///
///There is an upper limit on the number of queues that may be kept
///in memory at a given time. The default limit is 10.
+ (NSOperationQueue *)queueNamed:(NSString *)queueName;

///Returns a common catch-all queue suitable for use for short-lived background tasks.
///
///The returned queue is subject to the same rules as
///all other queues vended by the RKQueueManager class.
+ (NSOperationQueue *)commonQueue;

@end
