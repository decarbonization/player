//
//  RKURLRequestPromise.m
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 12/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKURLRequestPromise.h"
#import "RKConnectivityManager.h"
#import "RKActivityManager.h"
#import "RKPossibility.h"

#if TARGET_OS_IPHONE
#   import <UIKit/UIKit.h>
#else
#   import <Cocoa/Cocoa.h>
#endif /* TARGET_OS_IPHONE */

NSString *const RKURLRequestPromiseErrorDomain = @"RKURLRequestPromiseErrorDomain";
NSString *const RKURLRequestPromiseCacheIdentifierErrorUserInfoKey = @"RKURLRequestPromiseCacheIdentifierErrorUserInfoKey";

static NSString *const kETagHeaderKey = @"Etag";
static NSString *const kDefaultETagKey = @"-1";

#pragma mark - RKPostProcessorBlock

RK_OVERLOADABLE RKPostProcessorBlock RKPostProcessorBlockChain(RKPostProcessorBlock source,
                                                               RKPostProcessorBlock refiner)
{
    NSCParameterAssert(source);
    NSCParameterAssert(refiner);
    
    return ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
        RKPossibility *refinedMaybeData = source(maybeData, request);
        return refiner(refinedMaybeData, request);
    };
}

RKPostProcessorBlock const kRKJSONPostProcessorBlock = ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
    return [maybeData refineValue:^RKPossibility *(NSData *data) {
        NSError *error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(result) {
            return [[RKPossibility alloc] initWithValue:result];
        } else {
            return [[RKPossibility alloc] initWithError:error];
        }
    }];
};

RKPostProcessorBlock const kRKImagePostProcessorBlock = ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
    return [maybeData refineValue:^RKPossibility *(NSData *data) {
#if TARGET_OS_IPHONE
        UIImage *image = [[UIImage alloc] initWithData:data];
#else
        NSImage *image = [[NSImage alloc] initWithData:data];
#endif /* TARGET_OS_IPHONE */
        if(image) {
            return [[RKPossibility alloc] initWithValue:image];
        } else {
            return [[RKPossibility alloc] initWithError:[NSError errorWithDomain:RKURLRequestPromiseErrorDomain
                                                                            code:'!img'
                                                                        userInfo:@{NSLocalizedDescriptionKey: @"Could not load image"}]];
        }
    }];
};

RKPostProcessorBlock const kRKPropertyListPostProcessorBlock = ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
    return [maybeData refineValue:^RKPossibility *(NSData *data) {
        NSError *error = nil;
        id result = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
        if(result) {
            return [[RKPossibility alloc] initWithValue:result];
        } else {
            return [[RKPossibility alloc] initWithError:error];
        }
    }];
};

#if RKURLRequestPromise_Option_TrackActiveRequests
#pragma mark - Tracking Active Requests

#warning RKURLRequestPromise_Option_TrackActiveRequests = 1

static CFMutableArrayRef GetSharedActiveRequestArray()
{
    static CFMutableArrayRef _ActiveRequests = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFArrayCallBacks callbacks = {
            .version = 0,
            .retain = NULL,
            .release = NULL,
            .copyDescription = &CFCopyDescription,
            .equal = &CFEqual,
        };
        _ActiveRequests = CFArrayCreateMutable(kCFAllocatorDefault, 0, &callbacks);
    });
    
    return _ActiveRequests;
}

static void AddRequestToActiveRequestArray(RKURLRequestPromise *request)
{
    CFMutableArrayRef sharedActiveRequestArray = GetSharedActiveRequestArray();
    @synchronized((__bridge NSMutableArray *)sharedActiveRequestArray) {
        CFArrayAppendValue(sharedActiveRequestArray, (__bridge const void *)request);
    }
}

static void RemoveRequestFromActiveRequestArray(RKURLRequestPromise *request)
{
    CFMutableArrayRef sharedActiveRequestArray = GetSharedActiveRequestArray();
    @synchronized((__bridge NSMutableArray *)sharedActiveRequestArray) {
        CFIndex indexOfRequest = CFArrayGetFirstIndexOfValue(sharedActiveRequestArray,
                                                             CFRangeMake(0, CFArrayGetCount(sharedActiveRequestArray)),
                                                             (__bridge const void *)request);
        if(indexOfRequest == kCFNotFound)
            return;
        
        CFArrayRemoveValueAtIndex(sharedActiveRequestArray, indexOfRequest);
    }
}

static CFIndex ActiveRequestArrayGetInstanteousCount()
{
    CFMutableArrayRef sharedActiveRequestArray = GetSharedActiveRequestArray();
    @synchronized((__bridge NSMutableArray *)sharedActiveRequestArray) {
        return CFArrayGetCount(sharedActiveRequestArray);
    }
}

static NSArray *ActiveRequestArrayGetInstanteousCopy()
{
    CFMutableArrayRef sharedActiveRequestArray = GetSharedActiveRequestArray();
    @synchronized((__bridge NSMutableArray *)sharedActiveRequestArray) {
        return [(__bridge NSMutableArray *)sharedActiveRequestArray copy];
    }
}

#pragma mark -

RK_INLINE void RequestDidIsBecomingActive(RKURLRequestPromise *request)
{
    AddRequestToActiveRequestArray(request);
}

RK_INLINE void RequestDidFail(RKURLRequestPromise *request)
{
    RemoveRequestFromActiveRequestArray(request);
}

RK_INLINE void RequestDidSucceed(RKURLRequestPromise *request)
{
    RemoveRequestFromActiveRequestArray(request);
}

RK_INLINE void RequestCancelled(RKURLRequestPromise *request)
{
    RemoveRequestFromActiveRequestArray(request);
}

RK_INLINE void RequestIsDeallocating(RKURLRequestPromise *request)
{
    RemoveRequestFromActiveRequestArray(request);
}

#else

static CFIndex ActiveRequestArrayGetInstanteousCount()
{
    NSLog(@"*** Warning: Attempting to get number of active RKURLRequestPromises when RKURLRequestPromise_Option_TrackActiveRequests is set to 0");
    return 0;
}

static NSArray *ActiveRequestArrayGetInstanteousCopy()
{
    NSLog(@"*** Warning: Attempting to get active RKURLRequestPromises when RKURLRequestPromise_Option_TrackActiveRequests is set to 0");
    return nil;
}

#define RequestDidIsBecomingActive(...)
#define RequestDidFail(...)
#define RequestDidSucceed(...)
#define RequestCancelled(...)
#define RequestIsDeallocating(...)
#define RequestDidIsBecomingActive(...)

#endif /* RKURLRequestPromise_Option_TrackActiveRequests */

#pragma mark -

@interface RKURLRequestPromise () <NSURLConnectionDelegate>

#pragma mark - Internal Properties

///The underlying connection.
@property NSURLConnection *connection;

///Whether or not the cache has been successfully loaded.
@property BOOL isCacheLoaded;

#pragma mark - Readwrite Properties

///Readwrite
@property (readwrite, RK_NONATOMIC_IOSONLY) NSURLRequest *request;

///Readwrite.
@property (copy, readwrite) NSHTTPURLResponse *response;

///Readwrite
@property (readwrite, RK_NONATOMIC_IOSONLY) id <RKURLRequestPromiseCacheManager> cacheManager;

///Readwrite
@property (readwrite, RK_NONATOMIC_IOSONLY) BOOL useCacheWhenOffline;

@end

#pragma mark -

@implementation RKURLRequestPromise {
    BOOL _isInOfflineMode;
    NSMutableData *_loadedData;
}

#pragma mark - Tracking Requests

+ (NSUInteger)numberOfActiveRequests
{
    return ActiveRequestArrayGetInstanteousCount();
}

+ (NSArray *)activeRequests
{
    return ActiveRequestArrayGetInstanteousCopy();
}

+ (void)prettyPrintActiveRequests
{
    NSArray *activeRequests = [self activeRequests];
    puts([[NSString stringWithFormat:@"-- begin %ld active requests --", (unsigned long)activeRequests.count] UTF8String]);
    putc('\n', stdout);
    
    for (RKURLRequestPromise *activeRequest in activeRequests) {
        NSString *method = activeRequest.request.HTTPMethod;
        NSURL *url = activeRequest.request.URL;
        puts([[NSString stringWithFormat:@"%@ %@", method, url] UTF8String]);
        
        NSString *cacheIdentiifer = activeRequest.cacheIdentifier;
        id <RKURLRequestPromiseCacheManager> cacheManager = activeRequest.cacheManager;
        puts([[NSString stringWithFormat:@"\twith cache id \"%@\" in manager %@", cacheIdentiifer, cacheManager] UTF8String]);
        
        NSString *requestQueueName = activeRequest.requestQueue.name ?: [activeRequest.requestQueue description];
        puts([[NSString stringWithFormat:@"\ton request queue %@", requestQueueName] UTF8String]);
        
        putc('\n', stdout);
    }
    
    puts([[NSString stringWithFormat:@"-- end %ld active requests --", (unsigned long)activeRequests.count] UTF8String]);
}

#pragma mark - Lifecycle

- (void)dealloc
{
    RequestIsDeallocating(self);
    [self cancel:nil];
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithRequest:(NSURLRequest *)request
         cacheManager:(id <RKURLRequestPromiseCacheManager>)cacheManager
  useCacheWhenOffline:(BOOL)useCacheWhenOffline
         requestQueue:(NSOperationQueue *)requestQueue
{
    NSParameterAssert(request);
    NSParameterAssert(requestQueue);
    
    if((self = [super init])) {
        self.request = request;
        self.cacheManager = cacheManager;
        self.useCacheWhenOffline = useCacheWhenOffline;
        self.requestQueue = requestQueue;
        
        self.cacheIdentifier = [request.URL absoluteString];
        
        self.connectivityManager = [RKConnectivityManager defaultInternetConnectivityManager];
    }
    
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request
         cacheManager:(id <RKURLRequestPromiseCacheManager>)cacheManager
         requestQueue:(NSOperationQueue *)requestQueue
{
    return [self initWithRequest:request cacheManager:cacheManager useCacheWhenOffline:YES requestQueue:requestQueue];
}

- (id)initWithRequest:(NSURLRequest *)request requestQueue:(NSOperationQueue *)requestQueue
{
    return [self initWithRequest:request cacheManager:nil useCacheWhenOffline:NO requestQueue:requestQueue];
}

#pragma mark - Identity

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p %@ to %@>", NSStringFromClass([self class]), self, self.request.HTTPMethod, self.request.URL];
}

#pragma mark - Realization

- (void)fire
{
    NSAssert((self.connection == nil),
             @"Cannot realize a %@ more than once.", NSStringFromClass([self class]));
    
    [_requestQueue addOperationWithBlock:^{
        @synchronized(self) {
            _loadedData = [NSMutableData new];
        }
        
        _isInOfflineMode = !self.connectivityManager.isConnected;
        [[RKActivityManager sharedActivityManager] incrementActivityCount];
        
        if(_preflight) {
            NSError *preflightError = nil;
            NSURLRequest *newRequest = nil;
            if((newRequest = _preflight(self.request, &preflightError))) {
                self.request = newRequest;
            } else {
                [self invokeFailureCallbackWithError:preflightError];
                return;
            }
        }
        
        RequestDidIsBecomingActive(self);
        
        if(_isInOfflineMode) {
            [self.requestQueue addOperationWithBlock:^{
                [self loadCacheAndReportError:YES];
            }];
        } else {
            self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                              delegate:self
                                                      startImmediately:NO];
            
            [self.connection setDelegateQueue:self.requestQueue];
            [self.connection start];
        }
        
#if RKURLRequestPromise_Option_LogRequests
        NSLog(@"[DEBUG] Outgoing request to <%@>, POST data <%@>", self.request.URL, (self.request.HTTPBody? [[NSString alloc] initWithData:self.request.HTTPBody encoding:NSUTF8StringEncoding] : @"(none)"));
#endif /* RKURLRequestPromise_Option_LogRequests */
    }];
}

- (void)cancel:(id)sender
{
    if(!self.cancelled && _connection) {
        [self.connection cancel];
        @synchronized(self) {
             _loadedData = nil;
        }
        
#if RKURLRequestPromise_Option_LogRequests
        NSLog(@"[DEBUG] Outgoing request to <%@> cancelled", self.request.URL);
#endif /* RKURLRequestPromise_Option_LogRequests */
        
        [[RKActivityManager sharedActivityManager] decrementActivityCount];
        
        self.cancelled = YES;
        
        RequestCancelled(self);
    }
}

#pragma mark - Cache Support

- (BOOL)loadCacheAndReportError:(BOOL)reportError
{
    if(!self.cacheManager || self.cacheIdentifier == nil)
        return NO;
    
    if(self.cancelled) {
        if(!_isInOfflineMode)
            [[RKActivityManager sharedActivityManager] decrementActivityCount];
        
        return YES;
    }
    
    NSError *error = nil;
    NSData *data = [self.cacheManager cachedDataForIdentifier:self.cacheIdentifier error:&error];
    if(data) {
        self.isCacheLoaded = YES;
        
        [self invokeSuccessCallbackWithData:data];
    } else {
        NSError *removeError = nil;
        BOOL removedCache = [self.cacheManager removeCacheForIdentifier:self.cacheIdentifier error:&removeError];
        
        if(reportError) {
            NSDictionary *userInfo = nil;
            if(removedCache) {
                userInfo = @{
                    NSUnderlyingErrorKey: error,
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Could not load cached data for identifier %@.", self.cacheIdentifier],
                    RKURLRequestPromiseCacheIdentifierErrorUserInfoKey: self.cacheIdentifier,
                };
            } else {
                userInfo = @{
                    NSUnderlyingErrorKey: error,
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Could not load cached data for identifier %@.", self.cacheIdentifier],
                    RKURLRequestPromiseCacheIdentifierErrorUserInfoKey: self.cacheIdentifier,
                    @"RKURLRequestPromiseCacheRemovalErrorUserInfoKey": removeError,
                };
            }
            NSError *highLevelError = [NSError errorWithDomain:RKURLRequestPromiseErrorDomain
                                                          code:kRKURLRequestPromiseErrorCannotLoadCache
                                                      userInfo:userInfo];
            [self invokeFailureCallbackWithError:highLevelError];
            
            return NO;
        }
    }
    
    return YES;
}

- (void)loadCachedDataWithCallbackQueue:(NSOperationQueue *)callbackQueue block:(RKURLRequestPromiseCacheLoadingBlock)block
{
    NSParameterAssert(callbackQueue);
    NSParameterAssert(block);
    
    if(!self.cacheManager || self.cacheIdentifier == nil)
        return;
    
    [self.requestQueue addOperationWithBlock:^{
        NSError *error = nil;
        NSData *data = [self.cacheManager cachedDataForIdentifier:self.cacheIdentifier error:&error];
        if(data) {
            RKPossibility *maybeValue = [[RKPossibility alloc] initWithValue:data];
            if(self.postProcessor)
                maybeValue = self.postProcessor(maybeValue, self);
            
            [callbackQueue addOperationWithBlock:^{
                block(maybeValue);
            }];
        } else if(error) {
            NSDictionary *userInfo = @{
                NSUnderlyingErrorKey: error,
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Could not load cached data for identifier %@.", self.cacheIdentifier],
                RKURLRequestPromiseCacheIdentifierErrorUserInfoKey: self.cacheIdentifier,
            };
            NSError *highLevelError = [NSError errorWithDomain:RKURLRequestPromiseErrorDomain
                                                          code:kRKURLRequestPromiseErrorCannotLoadCache
                                                      userInfo:userInfo];
            [callbackQueue addOperationWithBlock:^{
                block([[RKPossibility alloc] initWithError:highLevelError]);
            }];
        } else {
            [callbackQueue addOperationWithBlock:^{
                block([[RKPossibility alloc] initEmpty]);
            }];
        }
    }];
}

- (void)loadCachedDataWithBlock:(RKURLRequestPromiseCacheLoadingBlock)block
{
    NSParameterAssert(block);
    
    [self loadCachedDataWithCallbackQueue:[NSOperationQueue currentQueue] block:block];
}

#pragma mark - Invoking Callbacks

- (void)invokeSuccessCallbackWithData:(NSData *)data
{
    if(self.cancelled)
        return;
    
    [[RKActivityManager sharedActivityManager] decrementActivityCount];
    
#if RKURLRequestPromise_Option_LogResponses
    NSLog(@"[DEBUG] %@Response for request to <%@>: %@", (_isInOfflineMode? @"(offline) " : @""), self.request.URL, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
#endif /* RKURLRequestPromise_Option_LogResponses */
    
    RKPossibility *maybeValue = nil;
    if(_postProcessor) {
        maybeValue = _postProcessor([[RKPossibility alloc] initWithValue:data], self);
    }
    
    //Post-processors can be long running.
    if(self.cancelled)
        return;
    
    RequestDidSucceed(self);
    
    if(maybeValue) {
        if(maybeValue.state == kRKPossibilityStateError) {
            [self reject:maybeValue.error];
        } else {
            [self accept:maybeValue.value];
        }
    } else {
        [self accept:data];
    }
}

- (void)invokeFailureCallbackWithError:(NSError *)error
{
    if(self.cancelled)
        return;
    
    [[RKActivityManager sharedActivityManager] decrementActivityCount];
    
#if RKURLRequestPromise_Option_LogErrors
    NSLog(@"[DEBUG] Error for request to <%@>: %@", self.request.URL, error);
#endif /* RKURLRequestPromise_Option_LogErrors */
    
    RequestDidFail(self);
    
    [self reject:error];
}

#pragma mark - <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    switch (error.code) {
        case NSURLErrorCannotFindHost:
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorDNSLookupFailed:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorRedirectToNonExistentLocation:
        case NSURLErrorBadServerResponse: {
            if(self.isCacheLoaded) {
                //Return early, for we have loaded our cache.
                return;
            }
            
            break;
        }
            
        default: {
            break;
        }
    }
    
    [self invokeFailureCallbackWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    self.response = response;
    
    if(!self.cacheManager || self.cancelled || self.cacheIdentifier == nil)
        return;
    
    NSString *etag = response.allHeaderFields[kETagHeaderKey];
    NSString *cachedEtag = [self.cacheManager revisionForIdentifier:self.cacheIdentifier];
    if(etag && cachedEtag && [etag caseInsensitiveCompare:cachedEtag] == NSOrderedSame) {
        [self.connection cancel];
        @synchronized(self) {
            _loadedData = nil;
        }
        
        if(self.cancelWhenRemoteDataUnchanged) {
            [[RKActivityManager sharedActivityManager] decrementActivityCount];
        } else {
            [self loadCacheAndReportError:YES];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    @synchronized(self) {
        [_loadedData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(self.cancelled)
        return;
    
    __block NSData *loadedData = nil;
    @synchronized(self) {
        loadedData = _loadedData;
    }
    
    if(self.cacheManager) {
        NSString *etag = self.response.allHeaderFields[kETagHeaderKey];
        if(!etag && self.useCacheWhenOffline)
            etag = kDefaultETagKey;
        
        if(etag) {
            NSError *error = nil;
            if(![self.cacheManager cacheData:loadedData
                               forIdentifier:self.cacheIdentifier
                                withRevision:etag
                                       error:&error]) {
                NSDictionary *userInfo = @{
                    NSUnderlyingErrorKey: error,
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Could not write data to cache for identifier %@.", self.cacheIdentifier],
                    RKURLRequestPromiseCacheIdentifierErrorUserInfoKey: self.cacheIdentifier,
                };
                NSError *highLevelError = [NSError errorWithDomain:RKURLRequestPromiseErrorDomain
                                                              code:kRKURLRequestPromiseErrorCannotWriteCache
                                                          userInfo:userInfo];
                [self invokeFailureCallbackWithError:highLevelError];
            }
        }
    }
    
    [self invokeSuccessCallbackWithData:loadedData];
    
    _connection = nil;
    @synchronized(self) {
        _loadedData = nil;
    }
}

#pragma mark -

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [self.authenticationHandler request:self canHandlerAuthenticateProtectionSpace:protectionSpace];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self.authenticationHandler request:self handleAuthenticationChallenge:challenge];
}

@end
