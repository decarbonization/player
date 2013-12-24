//
//  LastFMScrobbler.h
//  Pinna
//
//  Created by Peter MacWhinnie on 2/19/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Service.h"

@class RKURLRequestPromise;

///The LastFMSession class encapsulates asynchronous interaction
///with the Last.fm service in the Pinna application.
@interface LastFMSession : NSObject <Service>

///Returns the default LastFMSession object, creating it if it does not already exist.
+ (LastFMSession *)defaultSession;

#pragma mark - Properties

///The session key of the scrobbler.
@property (copy) NSString *sessionKey;

///Whether or not the scrobbler is authorized.
@property (readonly) BOOL isAuthorized;

///Whether or not the scrobbler is authorizing;
@property (readonly) BOOL isAuthorizing;

#pragma mark - Authentication

///Returns a promise to start the authorization process with Last.fm by fetching a login token.
///
/// \result A promise that will yield a URL for an authorization web page to be displayed in a web view or browser upon success.
- (RKURLRequestPromise *)startAuthorization RK_REQUIRE_RESULT_USED;

///Returns a promise to finish the authorization process.
///
/// \result A promise that will yield a dictionary describing the authorized user upon success.
///
///This method should be called after the user has completed the
///authorization at the URL yielded by `-[LastFMScrobbler startAuthorization]`.
- (RKURLRequestPromise *)finishAuthorization RK_REQUIRE_RESULT_USED;

///Cancels any pending authorization process.
- (void)cancelAuthorization;

#pragma mark - Talking to Last.fm

///Returns a promise to load the info of the user that is currently logged in.
- (RKURLRequestPromise *)userInfo RK_REQUIRE_RESULT_USED;

///Returns a promise to invoke a given API method on Last.fm.
///
/// \param  methodName  The name of the method to invoke. Required.
/// \param  parameters  The parameters to pass onto the request. Basic JSON values only. Required.
/// \param  HTTPMethod  The HTTPMethod (@"POST" or @"GET") to use. Required.
///
/// \result A promise that upon success will yield a dictionary.
///
- (RKURLRequestPromise *)invokeMethodWithName:(NSString *)methodName parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)HTTPMethod RK_REQUIRE_RESULT_USED;

@end
