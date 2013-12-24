//
//  RKFileSystemCacheManager.m
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 1/7/13.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKFileSystemCacheManager.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const kMaxCacheSize = @"__maxCacheSize";
static NSString *const kCacheSize = @"__cacheSize";

static NSString *const kRevisionKey = @"revision";
static NSString *const kLastAccessedDateKey = @"lastAccessDate";
static NSString *const kDataSizeKey = @"dataSize";

static NSTimeInterval const kExpirationInterval = (RK_TIME_DAY * 7.0);
static NSUInteger kDefaultMaxCacheSize = (1024 * 30) /* 30 MB */;

@implementation RKFileSystemCacheManager {
    NSURL *_cacheLocation;
    NSURL *_cacheMetadataLocation;
    
    dispatch_queue_t _accessControlQueue;
    NSMutableDictionary *_cacheMetadata;
}

#pragma mark - Lifecycle

static NSTimeInterval const kMaintenanceTimerInterval = (RK_TIME_MINUTE * 5.0);

+ (dispatch_source_t)maintenanceTimer
{
    static dispatch_source_t maintenanceTimer = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        maintenanceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        
        dispatch_source_set_timer(maintenanceTimer,
                                  dispatch_time(DISPATCH_TIME_NOW, 60.0 * NSEC_PER_SEC),
                                  kMaintenanceTimerInterval * NSEC_PER_SEC,
                                  kMaintenanceTimerInterval / 2);
        
        dispatch_source_set_event_handler(maintenanceTimer, ^{
            [[RKFileSystemCacheManager sharedCacheManager] preformMaintenance];
        });
    });
    
    return maintenanceTimer;
}

+ (instancetype)sharedCacheManager
{
    static RKFileSystemCacheManager *sharedCacheManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCacheManager = [self new];
        
        dispatch_resume([self maintenanceTimer]);
    });
    
    return sharedCacheManager;
}

#pragma mark -

- (id)init
{
    if((self = [super init])) {
        _accessControlQueue = dispatch_queue_create("com.roundabout.RoundaboutKit.RKURLRequestPromiseCacheManager.accessQueue", 0);
        dispatch_barrier_async(_accessControlQueue, ^{
            _cacheLocation = [self cacheLocation];
            if(![_cacheLocation checkResourceIsReachableAndReturnError:nil]) {
                NSError *error = nil;
                if(![[NSFileManager defaultManager] createDirectoryAtURL:_cacheLocation
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error]) {
                    [NSException raise:NSInternalInconsistencyException format:@"Could not create bucket location %@. %@", _cacheLocation, error];
                }
            }
            
            _cacheMetadataLocation = [self locationForMetadata];
            _cacheMetadata = [NSMutableDictionary dictionaryWithContentsOfURL:_cacheMetadataLocation] ?: [NSMutableDictionary dictionary];
        });
    }
    
    return self;
}

#pragma mark - Locations

///Returns the location of the cache manager's directory.
- (NSURL *)cacheLocation
{
    NSError *error = nil;
    NSURL *cachesLocation = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                                   inDomain:NSUserDomainMask
                                                          appropriateForURL:nil
                                                                     create:YES
                                                                      error:&error];
    NSAssert(cachesLocation != nil, @"Could not find caches directory. %@", error);
    return [[cachesLocation URLByAppendingPathComponent:[[NSBundle bundleForClass:[self class]] bundleIdentifier]] URLByAppendingPathComponent:@"RKFileSystemCache"];
}

///Returns the location of a bucket's metadata file.
- (NSURL *)locationForMetadata
{
    return [[self cacheLocation] URLByAppendingPathComponent:@"__Metadata.plist"];
}

#pragma mark - Properties

- (void)setMaxCacheSize:(NSUInteger)maxCacheSize
{
    dispatch_barrier_sync(_accessControlQueue, ^{
        _cacheMetadata[kCacheSize] = @(maxCacheSize);
    });
}

- (NSUInteger)maxCacheSize
{
    __block NSUInteger maxCacheSize = 0;
    dispatch_sync(_accessControlQueue, ^{
        maxCacheSize = [_cacheMetadata[kMaxCacheSize] unsignedIntegerValue] ?: kDefaultMaxCacheSize;
    });
    
    return maxCacheSize;
}

- (NSUInteger)cacheSize
{
    __block NSUInteger cacheSize = 0;
    dispatch_sync(_accessControlQueue, ^{
        cacheSize = [_cacheMetadata[kCacheSize] unsignedIntegerValue];
    });
    
    return cacheSize;
}

#pragma mark - Maintenance

void RKFileSystemCacheManagerEmitCacheRemovalErrorWarning(NSError *error)
{
#if RoundaboutKit_EmitWarnings
    NSLog(@"*** Warning, could not remove expired cached data. Add a breakpoint to RKFileSystemCacheManagerEmitCacheRemovalErrorWarning to debug. Error: %@", error);
#endif /* RoundaboutKit_EmitWarnings */
}

///Enumerates a given metadata hash and expunges any cache which has not been recently accessed.
///
/// \param  metadata    A copy of the cache metadata with the special keys removed.
///
- (void)removeExpiredCacheWithMetadata:(NSDictionary *)metadata
{
    [metadata enumerateKeysAndObjectsUsingBlock:^(NSString *sanitizedIdentifier, NSDictionary *itemMetadata, BOOL *stop) {
        NSDate *dateLastAccessed = itemMetadata[kLastAccessedDateKey];
        if(!dateLastAccessed || -[dateLastAccessed timeIntervalSinceNow] > kExpirationInterval) {
            NSError *error = nil;
            if(![self removeCacheForSanitizedIdentifier:sanitizedIdentifier error:&error]) {
                RKFileSystemCacheManagerEmitCacheRemovalErrorWarning(error);
            }
        }
    }];
}

///Checks if the cache has exceeded the limits set for it, subsequently
///enumerating and expunging data until the cache is within acceptable limits.
///
/// \param  metadata    A copy of the cache metadata with the special keys removed.
///
- (void)removeExcessCacheWithMetadata:(NSDictionary *)metadata
{
    //The accessors for these properties can deadlock.
    NSUInteger maxCacheSize = [metadata[kMaxCacheSize] unsignedIntegerValue] ?: kDefaultMaxCacheSize;
    NSUInteger cacheSize = [metadata[kCacheSize] unsignedIntegerValue];
    
    if(cacheSize > maxCacheSize) {
        NSArray *weightedSanitizedIdentifiers = [metadata keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
            return [left[kLastAccessedDateKey] compare:right[kLastAccessedDateKey]];
        }];
        
        for (NSString *sanitizedIdentifier in weightedSanitizedIdentifiers) {
            NSDictionary *itemMetadata = metadata[sanitizedIdentifier];
            
            NSError *error = nil;
            if(![self removeCacheForSanitizedIdentifier:sanitizedIdentifier error:&error]) {
                RKFileSystemCacheManagerEmitCacheRemovalErrorWarning(error);
            }
            
            cacheSize -= [itemMetadata[kDataSizeKey] unsignedIntegerValue];
            
            if(cacheSize <= maxCacheSize)
                break;
        }
    }
}

- (void)preformMaintenance
{
    __block NSMutableDictionary *metadataCopy = nil;
    dispatch_sync(_accessControlQueue, ^{
        metadataCopy = [_cacheMetadata mutableCopy];
    });
    
    [metadataCopy removeObjectForKey:kMaxCacheSize];
    [metadataCopy removeObjectForKey:kCacheSize];
    
    [self removeExpiredCacheWithMetadata:metadataCopy];
    [self removeExcessCacheWithMetadata:metadataCopy];
}

#pragma mark - Internal

///Writes the metadata dictionary to the file system.
///
///This method assumes it has been surrounded by a queue barrier.
- (void)synchronizeMetadata
{
    [_cacheMetadata writeToURL:_cacheMetadataLocation atomically:YES];
}

- (BOOL)removeCacheForSanitizedIdentifier:(NSString *)sanitizedIdentifier error:(NSError **)outError
{
    NSParameterAssert(sanitizedIdentifier);
    
    __block BOOL success = YES;
    __block NSError *error = nil;
    dispatch_barrier_sync(_accessControlQueue, ^{
        NSURL *dataLocation = [_cacheLocation URLByAppendingPathComponent:sanitizedIdentifier];
        
        if([[NSFileManager defaultManager] removeItemAtURL:dataLocation error:&error] || error.code == NSFileNoSuchFileError) {
            NSUInteger newCacheSize = [_cacheMetadata[kCacheSize] unsignedIntegerValue] - [_cacheMetadata[sanitizedIdentifier][kDataSizeKey] unsignedIntegerValue];
            _cacheMetadata[kCacheSize] = @(newCacheSize);
            
            [_cacheMetadata removeObjectForKey:sanitizedIdentifier];
            [self synchronizeMetadata];
            
            error = nil;
        } else {
            success = NO;
        }
    });
    
    if(outError) *outError = error;
    
    return success;
}

#pragma mark - <RKURLRequestPromiseCacheManager>

- (NSString *)revisionForIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier);
    
    __block NSString *revision = nil;
    dispatch_sync(_accessControlQueue, ^{
        NSString *sanitizedIdentifier = RKStringGetMD5Hash(identifier);
        revision = _cacheMetadata[sanitizedIdentifier][kRevisionKey];
    });
    
    return revision;
}

- (BOOL)cacheData:(NSData *)data forIdentifier:(NSString *)identifier withRevision:(NSString *)revision error:(NSError **)error
{
    NSParameterAssert(identifier);
    NSParameterAssert(revision);
    
    __block BOOL success = YES;
    dispatch_barrier_sync(_accessControlQueue, ^{
        NSString *sanitizedIdentifier = RKStringGetMD5Hash(identifier);
        NSURL *dataLocation = [_cacheLocation URLByAppendingPathComponent:sanitizedIdentifier];
        
        if([data writeToURL:dataLocation options:NSAtomicWrite error:error]) {
            _cacheMetadata[sanitizedIdentifier] = @{ kRevisionKey: revision,
                                                     kLastAccessedDateKey: [NSDate date],
                                                     kDataSizeKey: @(data.length) };
            
            NSUInteger newCacheSize = [_cacheMetadata[kCacheSize] unsignedIntegerValue] + data.length;
            _cacheMetadata[kCacheSize] = @(newCacheSize);
            
            [self synchronizeMetadata];
        } else {
            success = NO;
        }
    });
    
    return success;
}

- (NSData *)cachedDataForIdentifier:(NSString *)identifier error:(NSError **)outError
{
    NSParameterAssert(identifier);
    
    __block NSError *error = nil;
    __block NSData *data = nil;
    dispatch_sync(_accessControlQueue, ^{
        NSString *sanitizedIdentifier = RKStringGetMD5Hash(identifier);
        NSURL *dataLocation = [_cacheLocation URLByAppendingPathComponent:sanitizedIdentifier];
        data = [NSData dataWithContentsOfURL:dataLocation options:0 error:&error];
        
        NSMutableDictionary *itemMetadata = [_cacheMetadata[sanitizedIdentifier] mutableCopy];
        if(itemMetadata) {
            NSDate *lastAccessed = itemMetadata[kLastAccessedDateKey];
            itemMetadata[kLastAccessedDateKey] = [NSDate date];
            _cacheMetadata[sanitizedIdentifier] = itemMetadata;
            if(!lastAccessed || -[lastAccessed timeIntervalSinceNow] >= kExpirationInterval / 2.0) {
                dispatch_barrier_async(_accessControlQueue, ^{
                    [self synchronizeMetadata];
                });
            }
        }
    });
    
    if(data) {
        return data;
    } else {
        if(error.code == NSFileReadNoSuchFileError) {
            return nil;
        } else {
            if(outError) *outError = error;
            return nil;
        }
    }
}

- (BOOL)removeCacheForIdentifier:(NSString *)identifier error:(NSError **)outError
{
    NSParameterAssert(identifier);
    
    return [self removeCacheForSanitizedIdentifier:RKStringGetMD5Hash(identifier) error:outError];
}

- (BOOL)removeAllCache:(NSError **)outError
{
    __block BOOL success = YES;
    __block NSError *error = nil;
    dispatch_barrier_sync(_accessControlQueue, ^{
        if([[NSFileManager defaultManager] removeItemAtURL:_cacheLocation error:&error] || error.code == NSFileNoSuchFileError) {
            NSNumber *maxCacheSize = _cacheMetadata[kMaxCacheSize] ?: @(kDefaultMaxCacheSize);
            [_cacheMetadata removeAllObjects];
            _cacheMetadata[kMaxCacheSize] = maxCacheSize;
            [self synchronizeMetadata];
            
            error = nil;
        } else {
            success = NO;
        }
    });
    
    if(outError) *outError = error;
    
    return success;
}

@end
