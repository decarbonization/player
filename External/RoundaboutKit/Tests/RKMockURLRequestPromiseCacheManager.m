//
//  RKMockURLRequestPromiseCacheManager.m
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 5/6/13.
//
//

#import "RKMockURLRequestPromiseCacheManager.h"

NSString *const kRKMockURLRequestPromiseCacheManagerItemRevisionKey = @"revision";
NSString *const kRKMockURLRequestPromiseCacheManagerItemDataKey = @"data";
NSString *const kRKMockURLRequestPromiseCacheManagerItemErrorKey = @"error";

@interface RKMockURLRequestPromiseCacheManager ()

@property (readwrite) BOOL wasCalledFromMainThread;
@property (readwrite) BOOL revisionForIdentifierWasCalled;
@property (readwrite) BOOL cacheDataForIdentifierWithRevisionErrorWasCalled;
@property (readwrite) BOOL cachedDataForIdentifierErrorWasCalled;
@property (readwrite) BOOL removeCacheForIdentifierErrorWasCalled;

@end

@implementation RKMockURLRequestPromiseCacheManager {
    NSMutableDictionary *_cachedData;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithItems:(NSDictionary *)items
{
    if((self = [super init])) {
        _cachedData = [items ?: @{} mutableCopy];
    }
    
    return self;
}

- (NSString *)revisionForIdentifier:(NSString *)identifier
{
    if([NSThread isMainThread])
        self.wasCalledFromMainThread = YES;
    
    self.revisionForIdentifierWasCalled = YES;
    
    @synchronized(_cachedData) {
        NSDictionary *item = _cachedData[identifier];
        return item[kRKMockURLRequestPromiseCacheManagerItemRevisionKey];
    }
}

- (BOOL)cacheData:(NSData *)data forIdentifier:(NSString *)identifier withRevision:(NSString *)revision error:(NSError **)error
{
    if([NSThread isMainThread])
        self.wasCalledFromMainThread = YES;
    
    self.cacheDataForIdentifierWithRevisionErrorWasCalled = YES;
    
    @synchronized(_cachedData) {
        NSDictionary *item = _cachedData[identifier];
        if(item[kRKMockURLRequestPromiseCacheManagerItemErrorKey]) {
            if(error) *error = item[kRKMockURLRequestPromiseCacheManagerItemErrorKey];
            return NO;
        }
        
        _cachedData[identifier] = @{kRKMockURLRequestPromiseCacheManagerItemRevisionKey: revision,
                                    kRKMockURLRequestPromiseCacheManagerItemDataKey: data};
        return YES;
    }
}

- (NSData *)cachedDataForIdentifier:(NSString *)identifier error:(NSError **)error
{
    if([NSThread isMainThread])
        self.wasCalledFromMainThread = YES;
    
    self.cachedDataForIdentifierErrorWasCalled = YES;
    
    @synchronized(_cachedData) {
        NSDictionary *item = _cachedData[identifier];
        if(item[kRKMockURLRequestPromiseCacheManagerItemErrorKey]) {
            if(error) *error = item[kRKMockURLRequestPromiseCacheManagerItemErrorKey];
            return nil;
        }
        
        return item[kRKMockURLRequestPromiseCacheManagerItemDataKey];
    }
}

- (BOOL)removeCacheForIdentifier:(NSString *)identifier error:(NSError **)outError
{
    if([NSThread isMainThread])
        self.wasCalledFromMainThread = YES;
    
    self.removeCacheForIdentifierErrorWasCalled = YES;
    
    @synchronized(_cachedData) {
        [_cachedData removeObjectForKey:identifier];
    }
    
    return YES;
}

- (BOOL)removeAllCache:(NSError **)outError
{
    @synchronized(_cachedData) {
        [_cachedData removeAllObjects];
    }
    
    return YES;
}

#pragma mark - Deterministic Failure

- (void)setError:(NSError *)error forIdentifier:(NSString *)identifier
{
    NSParameterAssert(error);
    NSParameterAssert(identifier);
    
    @synchronized(_cachedData) {
        _cachedData[identifier] = @{kRKMockURLRequestPromiseCacheManagerItemErrorKey: error};
    }
}

@end
