//
//  RKMockURLProtocol.h
//  RoundaboutKitTests
//
//  Created by Kevin MacWhinnie on 5/6/13.
//
//

#import <Foundation/Foundation.h>

///The RKMockURLProtocolRoute class encapsulates a predetermined response to a given
///URL request used by the RKMockURLProtocol class to test the RoundaboutKit network stack.
///
///A route may either have its `.headers` and `.responseData` set, or its `.error` set.
///The `.error` property is given precedence over `.headers` and `.responseData`.
///
/// \seealso(RKMockURLProtocol)
@interface RKMockURLProtocolRoute : NSObject

///The URL.
@property NSURL *URL;

///The HTTP method.
@property (copy) NSString *method;

#pragma mark -

///The status code.
@property NSInteger statusCode;

///The headers.
@property (copy) NSDictionary *headers;

///The response data.
@property (copy) NSData *responseData;

#pragma mark -

///The error of the route.
@property NSError *error;

@end

#pragma mark -

///The RKMockURLProtocol class allows tests to override the responses for
///specific requests to aid in the testing of the RoundaboutKit network stack.
///
/// \seealso(RKMockURLProtocolRoute)
@interface RKMockURLProtocol : NSURLProtocol

///Override the response to a request that matches the given parameters.
///
/// \param  url         The URL of the request to intercept. Required.
/// \param  method      The HTTP method of the request. Required.
/// \param  statusCode  The HTTP status code to return.
/// \param  headers     The headers to yield. Required.
/// \param  data        The response data to yield. Required.
///
+ (void)on:(NSURL *)url withMethod:(NSString *)method yieldStatusCode:(NSInteger)statusCode headers:(NSDictionary *)headers data:(NSData *)data;

///Override the response to a request that matches the given parameters.
///
/// \param  url         The URL of the request to intercept. Required.
/// \param  method      The HTTP method of the request. Required.
/// \param  error       The error to yield. Required.
+ (void)on:(NSURL *)url withMethod:(NSString *)method yieldError:(NSError *)error;

#pragma mark -

///Remove all registered routes.
///
///This method should be called during the tearDown phase of tests.
+ (void)removeAllRoutes;

///The registered routes.
+ (NSArray *)routes;

@end
