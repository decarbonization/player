//
//  LastFMScrobbler.m
//  Pinna
//
//  Created by Peter MacWhinnie on 2/19/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "LastFMSession.h"
#import "LastFMDefines.h"
#import "Song.h"
#import "Account.h"

static NSString *const kLastFMAPIURLString = @"http://ws.audioscrobbler.com/2.0/?";

@implementation LastFMSession {
    NSString *_loginToken;
}

+ (LastFMSession *)defaultSession
{
    static LastFMSession *defaultSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultSession = [LastFMSession new];
    });
    
    return defaultSession;
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingIsAuthorized
{
	return [NSSet setWithObjects:@"sessionKey", nil];
}

- (BOOL)isAuthorized
{
	return _sessionKey != nil;
}

- (BOOL)isAuthorizing
{
	return (_loginToken != nil);
}

#pragma mark - Dispensing Requests

- (NSString *)hashStringForParameters:(NSDictionary *)parameters withSecret:(NSString *)secret
{
	NSParameterAssert(parameters);
	NSParameterAssert(secret);
	
	NSMutableString *hash = [NSMutableString string];
	
	for (NSString *key in [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		NSString *value = [parameters valueForKey:key];
		
		[hash appendFormat:@"%@%@", key, value];
	}
	
	[hash appendString:secret];
	
	return RKStringGetMD5Hash(hash);
}

- (RKURLRequestPromise *)invokeMethodWithName:(NSString *)methodName parameters:(NSDictionary *)parameters HTTPMethod:(NSString *)HTTPMethod
{
    NSParameterAssert(methodName);
    NSParameterAssert(parameters);
    NSParameterAssert(HTTPMethod);
    
    NSMutableDictionary *allParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    allParameters[@"method"] = methodName;
    allParameters[@"api_key"] = kLastFMPublicKey;
	if(self.sessionKey)
		allParameters[@"sk"] = self.sessionKey;
	
	allParameters[@"api_sig"] = [self hashStringForParameters:allParameters withSecret:kLastFMSecret];
	allParameters[@"format"] = @"json";
    
	NSMutableURLRequest *request = nil;
	if([HTTPMethod isEqualToString:@"POST"]) {
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kLastFMAPIURLString]];
		[request setHTTPBody:[RKDictionaryToURLParametersString(allParameters) dataUsingEncoding:NSUTF8StringEncoding]];
	} else {
		NSString *baseURLString = [kLastFMAPIURLString stringByAppendingString:RKDictionaryToURLParametersString(allParameters)];
		
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseURLString]];
	}
	[request setHTTPMethod:HTTPMethod];
    
    RKURLRequestPromise *requestPromise = [[RKURLRequestPromise alloc] initWithRequest:request
                                                                          cacheManager:nil
                                                                   useCacheWhenOffline:NO
                                                                          requestQueue:[RKQueueManager commonQueue]];
    requestPromise.postProcessor = RKPostProcessorBlockChain(kRKJSONPostProcessorBlock, ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
        return [maybeData refineValue:^RKPossibility *(NSDictionary *response) {
            if(RKFilterOutNSNull(response[@"error"])) {
                NSError *error = [NSError errorWithDomain:@"LastFMErrorDomain"
                                                     code:[response[@"error"] integerValue]
                                                 userInfo:@{NSLocalizedDescriptionKey: response[@"message"]}];
                return [[RKPossibility alloc] initWithError:error];
            }
            
            return [[RKPossibility alloc] initWithValue:response];
        }];
    });
    
    return requestPromise;
}

#pragma mark - Authentication

- (RKURLRequestPromise *)startAuthorization
{
    RKURLRequestPromise *startAuthorizationPromise = [self invokeMethodWithName:@"auth.getToken"
                                                                     parameters:@{}
                                                                     HTTPMethod:@"GET"];
    startAuthorizationPromise.postProcessor = RKPostProcessorBlockChain(startAuthorizationPromise.postProcessor, ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
        return [maybeData refineValue:^RKPossibility *(NSDictionary *response) {
            [self willChangeValueForKey:@"isAuthorizing"];
            _loginToken = RKFilterOutNSNull(response[@"token"]);
            [self didChangeValueForKey:@"isAuthorizing"];
            
            NSString *urlString = [NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@", kLastFMPublicKey, _loginToken];
            return [[RKPossibility alloc] initWithValue:[NSURL URLWithString:urlString]];
        }];
    });
    
    return startAuthorizationPromise;
}

- (RKURLRequestPromise *)finishAuthorization
{
    RKURLRequestPromise *finishAuthorizationPromise = [self invokeMethodWithName:@"auth.getSession"
                                                                      parameters:@{ @"token": _loginToken }
                                                                      HTTPMethod:@"GET"];
    finishAuthorizationPromise.postProcessor = RKPostProcessorBlockChain(finishAuthorizationPromise.postProcessor, ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
        return [maybeData refineValue:^RKPossibility *(NSDictionary *response) {
            self.sessionKey = RKJSONDictionaryGetObjectAtKeyPath(response, @"session.key");
            
            return [[RKPossibility alloc] initWithValue:response];
        }];
    });
    
    return finishAuthorizationPromise;
}

- (void)cancelAuthorization
{
	[self willChangeValueForKey:@"isAuthorizing"];
	_loginToken = nil;
	[self didChangeValueForKey:@"isAuthorizing"];
}

#pragma mark - Sessions

- (RKPromise *)reloginWithAccount:(Account *)account
{
    RKPromise *promise = [RKPromise new];
    [[RKQueueManager commonQueue] addOperationWithBlock:^{
        self.sessionKey = account.token;
        
        NSError *error = nil;
        NSDictionary *response = [[self userInfo] await:&error];
        if(response) {
            RKSetPersistentObject(kLastFMCachedUserInfoDefaultsKey, RKFilterOutNSNull(response[@"user"]));
            [promise accept:self];
        } else {
            [promise reject:error];
        }
    }];
    return promise;
}

- (RKPromise *)logout
{
    self.sessionKey = nil;
    return [RKPromise acceptedPromiseWithValue:self];
}

#pragma mark - Talking to Last.fm

- (RKURLRequestPromise *)userInfo
{
    NSAssert(self.isAuthorized, @"Cannot request user info without being authorized.");
    
    return [self invokeMethodWithName:@"user.getInfo"
                           parameters:@{}
                           HTTPMethod:@"GET"];
}

#pragma mark -

- (RKPromise *)updateNowPlayingWithSong:(Song *)song duration:(NSTimeInterval)duration
{
    NSParameterAssert(song);
    
    NSAssert(self.isAuthorized, @"Cannot update now playing without scrobbler being authorized, sorry.");
	
	NSDictionary *parameters = @{
        @"track": song.name,
        @"artist": song.artist,
        @"album": song.album,
        @"trackNumber": [NSString stringWithFormat:@"%ld", song.trackNumber],
        @"duration": [NSString stringWithFormat:@"%ld", (NSInteger)duration],
    };
    
    return [self invokeMethodWithName:@"track.updateNowPlaying"
                           parameters:parameters
                           HTTPMethod:@"POST"];
}

- (RKPromise *)scrobbleSong:(Song *)song duration:(NSTimeInterval)duration
{
    NSParameterAssert(song);
    
    NSAssert(self.isAuthorized, @"Cannot scrobble song without scrobbler being authorized, sorry.");
	
	NSDictionary *parameters = @{
        @"track": song.name,
        @"artist": song.artist,
        @"album": song.album,
        @"trackNumber": [NSString stringWithFormat:@"%ld", song.trackNumber],
        @"timestamp": [NSString stringWithFormat:@"%ld", (NSInteger)[song.lastPlayed timeIntervalSince1970]],
    };
    
    return [self invokeMethodWithName:@"track.scrobble"
                           parameters:parameters
                           HTTPMethod:@"POST"];
}

@end
