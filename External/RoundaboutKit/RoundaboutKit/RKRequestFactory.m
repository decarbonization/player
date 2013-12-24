//
//  RKRequestFactory.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/31/13.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKRequestFactory.h"
#import "RKURLRequestPromise.h"

@interface RKRequestFactory ()

@property (readwrite, RK_NONATOMIC_IOSONLY) NSURL *baseURL;
@property (readwrite, RK_NONATOMIC_IOSONLY) id <RKURLRequestPromiseCacheManager> readCacheManager;
@property (readwrite, RK_NONATOMIC_IOSONLY) id <RKURLRequestPromiseCacheManager> writeCacheManager;
@property (readwrite, RK_NONATOMIC_IOSONLY) NSOperationQueue *requestQueue;
@property (readwrite, copy, RK_NONATOMIC_IOSONLY) RKPostProcessorBlock postProcessor;

@end

@implementation RKRequestFactory

- (id)initWithBaseURL:(NSURL *)baseURL
     readCacheManager:(id <RKURLRequestPromiseCacheManager>)readCacheManager
    writeCacheManager:(id <RKURLRequestPromiseCacheManager>)writeCacheManager
         requestQueue:(NSOperationQueue *)requestQueue
        postProcessor:(RKPostProcessorBlock)postProcessor
{
    NSParameterAssert(baseURL);
    NSParameterAssert(requestQueue);
    
    if((self = [super init])) {
        self.baseURL = baseURL;
        self.readCacheManager = readCacheManager;
        self.writeCacheManager = writeCacheManager;
        self.requestQueue = requestQueue;
        self.postProcessor = postProcessor;
    }
    
    return self;
}

#pragma mark - Dispensing URLs

- (NSURL *)URLWithPath:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSParameterAssert(path);
    
    NSMutableString *urlString = [[self.baseURL absoluteString] mutableCopy];
    if(![urlString hasSuffix:@"/"] && ![path hasPrefix:@"/"])
        [urlString appendString:@"/"];
    
    if([urlString hasSuffix:@"/"] && [path hasPrefix:@"/"])
        [urlString deleteCharactersInRange:NSMakeRange(urlString.length - 1, 1)];
    
    [urlString appendString:path];
    
    if(parameters) {
        NSString *parameterString = RKDictionaryToURLParametersString(parameters);
        [urlString appendFormat:@"?%@", parameterString];
    }
    
    return [NSURL URLWithString:urlString];
}

#pragma mark - Dispensing NSURLRequests

- (NSURLRequest *)GETRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLWithPath:path parameters:parameters]];
    [request setHTTPMethod:@"GET"];
    return request;
}

- (NSURLRequest *)DELETERequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLWithPath:path parameters:parameters]];
    [request setHTTPMethod:@"DELETE"];
    return request;
}

#pragma mark -

- (NSData *)bodyForPayload:(id)body bodyType:(RKRequestFactoryBodyType)bodyType
{
    if(!body)
        return nil;
    
    switch (bodyType) {
        case kRKRequestFactoryBodyTypeData: {
            return body;
        }
            
        case kRKRequestFactoryBodyTypeURLParameters: {
            return [RKDictionaryToURLParametersString(body) dataUsingEncoding:NSUTF8StringEncoding];
        }
            
        case kRKRequestFactoryBodyTypeJSON: {
            NSError *error = nil;
            NSData *JSONData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
            if(!JSONData)
                [NSException raise:NSInternalInconsistencyException format:@"Could not convert %@ to JSON. %@", body, error];
            
            return JSONData;
        }
            
    }
}

- (NSURLRequest *)POSTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters body:(id)body bodyType:(RKRequestFactoryBodyType)bodyType
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLWithPath:path parameters:parameters]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[self bodyForPayload:body bodyType:bodyType]];
    return request;
}

- (NSURLRequest *)PUTRequestWithPath:(NSString *)path parameters:(NSDictionary *)parameters body:(id)body bodyType:(RKRequestFactoryBodyType)bodyType
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self URLWithPath:path parameters:parameters]];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:[self bodyForPayload:body bodyType:bodyType]];
    return request;
}

#pragma mark - Dispensing RKURLRequestPromises

- (RKURLRequestPromise *)requestPromiseWithRequest:(NSURLRequest *)request
{
    id <RKURLRequestPromiseCacheManager> cacheManager = [request.HTTPMethod isEqualToString:@"GET"]? self.readCacheManager : self.writeCacheManager;
    RKURLRequestPromise *requestPromise = [[RKURLRequestPromise alloc] initWithRequest:request
                                                                          cacheManager:cacheManager
                                                                          requestQueue:self.requestQueue];
    requestPromise.postProcessor = self.postProcessor;
    requestPromise.authenticationHandler = self.authenticationHandler;
    return requestPromise;
}

#pragma mark -

- (RKURLRequestPromise *)GETRequestPromiseWithPath:(NSString *)path parameters:(NSDictionary *)parameters
{
    return [self requestPromiseWithRequest:[self GETRequestWithPath:path parameters:parameters]];
}

- (RKURLRequestPromise *)DELETERequestPromiseWithPath:(NSString *)path parameters:(NSDictionary *)parameters
{
    return [self requestPromiseWithRequest:[self DELETERequestWithPath:path parameters:parameters]];
}

#pragma mark -

- (RKURLRequestPromise *)POSTRequestPromiseWithPath:(NSString *)path
                                         parameters:(NSDictionary *)parameters
                                            body:(id)body 
                                        bodyType:(RKRequestFactoryBodyType)bodyType
{
    return [self requestPromiseWithRequest:[self POSTRequestWithPath:path parameters:parameters body:body bodyType:bodyType]];
}

- (RKURLRequestPromise *)PUTRequestPromiseWithPath:(NSString *)path
                                        parameters:(NSDictionary *)parameters
                                           body:(id)body 
                                       bodyType:(RKRequestFactoryBodyType)bodyType
{
    return [self requestPromiseWithRequest:[self PUTRequestWithPath:path parameters:parameters body:body bodyType:bodyType]];
}

@end
