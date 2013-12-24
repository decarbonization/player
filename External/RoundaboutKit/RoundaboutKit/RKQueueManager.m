//
//  RKQueueManager.m
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 6/13/13.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKQueueManager.h"

///The maximum number of queues to keep around at once.
static NSUInteger const kCacheLimit = 10;

@implementation RKQueueManager

+ (NSCache *)queueCache
{
    static NSCache *queueCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queueCache = [NSCache new];
        queueCache.name = @"com.roundabout.rk.queueManager.queueCache";
        queueCache.countLimit = kCacheLimit;
    });
    
    return queueCache;
}

+ (NSOperationQueue *)queueNamed:(NSString *)queueName
{
    NSParameterAssert(queueName);
    
    NSCache *queueCache = [self queueCache];
    
    NSOperationQueue *queue = [queueCache objectForKey:queueName];
    if(!queue) {
        queue = [NSOperationQueue new];
        queue.name = queueName;
    }
    
    return queue;
}

+ (NSOperationQueue *)commonQueue
{
    return [self queueNamed:@"com.roundabout.rk.queueManager.commonQueue"];
}

@end
