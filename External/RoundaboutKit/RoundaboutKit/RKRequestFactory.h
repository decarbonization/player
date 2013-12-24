//
//  RKRequestFactory.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/31/13.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKURLRequestPromise.h"

///The different possible types of POST/PUT body types.
typedef NS_ENUM(NSUInteger, RKRequestFactoryBodyType) {
    ///The body is raw data.
    kRKRequestFactoryBodyTypeData = 0,
    
    ///The body is a dictionary that should be interpreted as URL parameters.
    kRKRequestFactoryBodyTypeURLParameters = 1,
    
    ///The body is a JSON object.
    kRKRequestFactoryBodyTypeJSON = 2,
};

///The RKRequestFactory class encapsulates the common logic necessary to create RKURLRequestPromises.
///
///A factory is capable of dispensing properly formed route URLs, NSURLRequests, and RKURLRequestPromises.
///
///A request factory contains two cache managers. One used exclusively for GET requests (the read manager),
///and one used for POST, PUT, and DELETE requests (the write manager). This is done with the belief that
///caching behaviour will likely vary in clients between reading and writing requests.
///
///RKRequestFactory is not intended to be subclassed.
@interface RKRequestFactory : NSObject

///Initialize the receiver with a given base URL.
///
/// \param  baseURL             The base URL used to construct requests. Required.
/// \param  readCacheManager    The cache manager to use for requests GET requests.
/// \param  writeCacheManager   The cache manager to use for POST, PUT, and DELETE requests.
/// \param  requestQueue        The queue to use for requests. Required.
/// \param  postProcessor       The post processor to use. Optional.
///
/// \result A fully initialized request factory.
///
///This is the designated initializer.
- (id)initWithBaseURL:(NSURL *)baseURL
     readCacheManager:(id <RKURLRequestPromiseCacheManager>)readCacheManager
    writeCacheManager:(id <RKURLRequestPromiseCacheManager>)writeCacheManager
         requestQueue:(NSOperationQueue *)requestQueue
        postProcessor:(RKPostProcessorBlock)postProcessor;

#pragma mark - Properties

///The base URL.
@property (readonly, RK_NONATOMIC_IOSONLY) NSURL *baseURL;

///The cache manager to use for GET requests.
@property (readonly, RK_NONATOMIC_IOSONLY) id <RKURLRequestPromiseCacheManager> readCacheManager;

///The cache manager to use for POST, PUT, and DELETE requests.
@property (readonly, RK_NONATOMIC_IOSONLY) id <RKURLRequestPromiseCacheManager> writeCacheManager;

///The queue to use for requests.
@property (readonly, RK_NONATOMIC_IOSONLY) NSOperationQueue *requestQueue;

///The post processor block to use.
@property (readonly, copy, RK_NONATOMIC_IOSONLY) RKPostProcessorBlock postProcessor;

#pragma mark -

///The authentication handler to use for requests.
@property (RK_NONATOMIC_IOSONLY) id <RKURLRequestAuthenticationHandler> authenticationHandler;

#pragma mark - Dispensing URLs

///Returns a new URL constructed from the receiver's base URL,
///a given path, and a given dictionary of parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
///
/// \result A newly constructed URL.
///
/// \seealso(RKDictionaryToURLParametersString)
- (NSURL *)URLWithPath:(NSString *)path parameters:(NSDictionary *)parameters;

#pragma mark - Dispensing NSURLRequests

///Returns a new GET request with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
///
/// \result A newly constructed URL request.
///
/// \seealso(RKDictionaryToURLParametersString)
- (NSURLRequest *)GETRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters;

///Returns a new DELETE request with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
///
/// \result A newly constructed URL request.
///
/// \seealso(RKDictionaryToURLParametersString)
- (NSURLRequest *)DELETERequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters;

#pragma mark -

///Returns a new POST request with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
/// \param  body     The body to use for the POST request. This value will be interpreted according to the value of bodyType.
/// \param  bodyType How the body parameter should be interpreted.
///
/// \result A newly constructed URL request.
///
/// \seealso(RKDictionaryToURLParametersString, RKRequestFactoryBodyType)
- (NSURLRequest *)POSTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters body:(id)body bodyType:(RKRequestFactoryBodyType)bodyType;

///Returns a new PUT request with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
/// \param  body     The body to use for the POST request. This value will be interpreted according to the value of bodyType.
/// \param  bodyType How the body parameter should be interpreted.
///
/// \result A newly constructed URL request.
///
/// \seealso(RKDictionaryToURLParametersString, RKRequestFactoryBodyType)
- (NSURLRequest *)PUTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters body:(id)body bodyType:(RKRequestFactoryBodyType)bodyType;

#pragma mark - Dispensing RKURLRequestPromises

///Returns a new GET request promise with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
///
/// \result A newly constructed URL request promise.
///
/// \seealso(RKDictionaryToURLParametersString)
- (RKURLRequestPromise *)GETRequestPromiseWithPath:(NSString *)path parameters:(NSDictionary *)parameters RK_REQUIRE_RESULT_USED;

///Returns a new DELETE request promise with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
///
/// \result A newly constructed URL request promise.
///
/// \seealso(RKDictionaryToURLParametersString)
- (RKURLRequestPromise *)DELETERequestPromiseWithPath:(NSString *)path parameters:(NSDictionary *)parameters RK_REQUIRE_RESULT_USED;

#pragma mark -

///Returns a new POST request promise with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
/// \param  body     The body to use for the POST request. This value will be interpreted according to the value of bodyType.
/// \param  bodyType How the body parameter should be interpreted.
///
/// \result A newly constructed URL request promise.
///
/// \seealso(RKDictionaryToURLParametersString, RKRequestFactoryBodyType)
- (RKURLRequestPromise *)POSTRequestPromiseWithPath:(NSString *)path
                                         parameters:(NSDictionary *)parameters
                                               body:(id)body
                                           bodyType:(RKRequestFactoryBodyType)bodyType RK_REQUIRE_RESULT_USED;

///Returns a new PUT request promise with a given path and parameters.
///
/// \param  path        The path to use. Required.
/// \param  parameters  The parameters. Keys must be strings and values must be able
///                     to be converted through `RKDictionaryToURLParametersString`. Optional.
/// \param  body     The body to use for the PUT request. This value will be interpreted according to the value of bodyType.
/// \param  bodyType How the body parameter should be interpreted.
///
/// \result A newly constructed URL request promise.
///
/// \seealso(RKDictionaryToURLParametersString, RKRequestFactoryBodyType)
- (RKURLRequestPromise *)PUTRequestPromiseWithPath:(NSString *)path
                                        parameters:(NSDictionary *)parameters
                                              body:(id)body
                                          bodyType:(RKRequestFactoryBodyType)bodyType RK_REQUIRE_RESULT_USED;

@end
