//
//  RKFileSystemCacheManager.h
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 1/7/13.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKURLRequestPromise.h"

///The RKFileSystemCacheManager class encapsulates a persistent data-agnostic cache manager.
///
///RKFileSystemCacheManager is asynchronously initialize to reduce the cost of calling
///`+[self sharedCacheManagerForBucket]` as the cache manager must perform file system IO
///when it is initialized. This means that any method calls before the initialization
///process has been completed may block longer than is otherwise typical.
///
///The methods on this class should always be called from a background thread.
///
///This class was formerly known as RKURLRequestPromiseCacheManager.
@interface RKFileSystemCacheManager : NSObject <RKURLRequestPromiseCacheManager>

///Returns the shared cache manager, creating it if it does not already exist.
+ (instancetype)sharedCacheManager;

#pragma mark - Properties

///The name of the bucket associated with this cache manager.
@property (readonly, copy) NSString *bucketName DEPRECATED_ATTRIBUTE;

///The maximum size of the cache. Defaults to 30 MB.
///
///Changing the value of this property will not affect
///the cache until its next maintenance cycle.
@property NSUInteger maxCacheSize;

///The estimated size of the cache.
@property (readonly) NSUInteger cacheSize;

@end
