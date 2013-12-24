//
//  ExfmSession.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/19/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "ExfmSession.h"

#import "Song.h"
#import "Account.h"

RKPostProcessorBlock const kExfmPostProcessor = ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
    return [kRKJSONPostProcessorBlock(maybeData, request) refineValue:^RKPossibility *(NSDictionary *response) {
        if([response[@"status_code"] integerValue] == 200) {
            return [[RKPossibility alloc] initWithValue:response];
        } else {
            NSError *error = [NSError errorWithDomain:@"ExfmErrorDomain"
                                                 code:[response[@"status_code"] integerValue]
                                             userInfo:@{NSLocalizedDescriptionKey: response[@"status_text"]}];
            return [[RKPossibility alloc] initWithError:error];
        }
    }];
};

@interface ExfmSession () <RKURLRequestAuthenticationHandler>

@end

@implementation ExfmSession {
	/** Info **/
	
	NSString *_username;
	NSString *_password;
	
	/** Internal **/
	
    RKFileSystemCacheManager *_cacheManager;
}

#pragma mark - Requests

+ (NSOperationQueue *)sessionRequestQueue
{
    static NSOperationQueue *sessionRequestQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sessionRequestQueue = [NSOperationQueue new];
        sessionRequestQueue.name = @"com.roundabout.pinna.ExfmSession.sessionRequestQueue";
    });
    
    return sessionRequestQueue;
}

+ (RKRequestFactory *)sharedRequestFactory
{
    static RKRequestFactory *sharedRequestFactory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRequestFactory = [[RKRequestFactory alloc] initWithBaseURL:[NSURL URLWithString:@"https://ex.fm/api/v3"]
                                                        readCacheManager:[RKFileSystemCacheManager sharedCacheManager]
                                                       writeCacheManager:nil
                                                            requestQueue:[self sessionRequestQueue]
                                                           postProcessor:kExfmPostProcessor];
        sharedRequestFactory.authenticationHandler = [self defaultSession];
    });
    
    return sharedRequestFactory;
}

#pragma mark - Lifecycle

+ (ExfmSession *)defaultSession
{
    static ExfmSession *defaultSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultSession = [ExfmSession new];
    });
    
    return defaultSession;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
	if((self = [super init])) {
        _cacheManager = [RKFileSystemCacheManager sharedCacheManager];
	}
	
	return self;
}

#pragma mark - Internal

- (NSString *)authenticatedRequestPOSTString
{
	return [NSString stringWithFormat:@"username=%@&password=%@", [_username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [_password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - Tools

+ (NSCharacterSet *)usernameCharacterSet
{
	static NSCharacterSet *usernameCharacterSet = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableCharacterSet *characterSet = [NSMutableCharacterSet new];
		[characterSet formUnionWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
		[characterSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
		[characterSet addCharactersInString:@"_"];
		
		usernameCharacterSet = [characterSet copy];
	});
	
	return usernameCharacterSet;
}

#pragma mark -

+ (BOOL)isValidEmailAddress:(NSString *)address
{
	NSParameterAssert(address);
	
	//From <http://cocoawithlove.com/2009/06/verifying-that-string-is-email-address.html>
	NSString *emailRegularExpression =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
	
	NSPredicate *regExPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegularExpression];
	return [regExPredicate evaluateWithObject:address];
}

+ (BOOL)isValidUsername:(NSString *)username
{
	NSParameterAssert(username);
	
	username = [username lowercaseString];
	
	if([username length] < 2 || [username length] > 25)
		return NO;
	
	if(![[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:[username characterAtIndex:0]])
		return NO;
	
	NSCharacterSet *usernameCharacterSet = [self usernameCharacterSet];
	for (NSUInteger index = 0, length = [username length]; index < length; index++) {
		unichar character = [username characterAtIndex:index];
		if(![usernameCharacterSet characterIsMember:character])
			return NO;
	}
	
	return YES;
}

+ (BOOL)isValidPassword:(NSString *)password
{
	NSParameterAssert(password);
	
	if([password length] < 4 || [password length] > 32)
		return NO;
	
	return YES;
}

#pragma mark - Properties

- (NSString *)username
{
	@synchronized(self) {
		return [_username copy];
	}
}

- (void)setUsername:(NSString *)username
{
	@synchronized(self) {
		_username = [username copy];
	}
	
#if !TARGET_OS_IPHONE
	[self updateCachedSongs];
#endif /* !TARGET_OS_IPHONE */
}

@synthesize password = _password;

+ (NSSet *)keyPathsForValuesAffectingIsAuthorized
{
	return [NSSet setWithObjects:@"username", @"password", nil];
}
- (BOOL)isAuthorized
{
	return (self.username && self.password);
}

#pragma mark - Sessions

- (RKPromise *)reloginWithAccount:(Account *)account
{
    RKPromise *promise = [RKPromise new];
    self.username = account.username;
    self.password = account.password;
    [promise accept:self];
    return promise;
}

- (RKPromise *)logout
{
    RKPromise *promise = [RKPromise new];
    self.username = nil;
    self.password = nil;
    [promise accept:self];
    return promise;
}

#pragma mark - User Suite

- (RKURLRequestPromise *)createUserWithName:(NSString *)name password:(NSString *)password email:(NSString *)email
{
	NSParameterAssert(name);
	NSParameterAssert(password);
	NSParameterAssert(email);
	
    return [[self.class sharedRequestFactory] POSTRequestPromiseWithPath:@"/user"
                                                              parameters:nil
                                                                    body:@{@"username": name, @"password": password, @"email": email}
                                                                bodyType:kRKRequestFactoryBodyTypeURLParameters];
}

- (RKURLRequestPromise *)userInfo
{
	NSString *path = [NSString stringWithFormat:@"/user/%@", [_username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:path
                                                              parameters:nil];
}

- (RKURLRequestPromise *)me
{
	NSAssert(self.isAuthorized, @"Not authenticated.");
	
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:@"/me"
                                                             parameters:@{@"username": _username, @"password": _password}];
}

- (RKURLRequestPromise *)verifyUsername:(NSString *)username password:(NSString *)password
{
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:@"/me"
                                                             parameters:@{@"username": username, @"password": password}];
}

#pragma mark -

- (RKPromise *)allLovedSongs
{
    RKPromise *promise = [RKPromise new];
    [[self.class sessionRequestQueue] addOperationWithBlock:^{
        NSMutableArray *allLovedSongs = [NSMutableArray array];
        NSError *error = nil;
        NSUInteger offset = 0;
        for (;;) {
            NSDictionary *response = [[self lovedSongsStartingAtOffset:offset] await:&error];
            if(!response)
                break;
            
            NSArray *remoteSongs = response[@"songs"];
            if([remoteSongs count] > 0) {
				[allLovedSongs addObjectsFromArray:remoteSongs];
				
				offset += 50;
			} else {
                break;
			}
        }
        
        if(error) {
            [promise reject:error];
        } else {
            [promise accept:allLovedSongs];
        }
    }];
    return promise;
}

- (RKPromise *)allLovedSongsOfFriends
{
    RKPromise *promise = [RKPromise new];
    [[self.class sessionRequestQueue] addOperationWithBlock:^{
        NSMutableArray *allLovedSongs = [NSMutableArray array];
        NSError *error = nil;
        NSUInteger offset = 0;
        for (;;) {
            NSDictionary *response = [[self lovedSongsOfFriendsFeedStartingAtOffset:offset] await:&error];
            if(!response)
                break;
            
            NSArray *remoteSongs = [response valueForKeyPath:@"activities.object"];
            if([remoteSongs count] > 0) {
				[allLovedSongs addObjectsFromArray:remoteSongs];
				
				offset += 50;
			} else {
                break;
			}
        }
        
        if(error) {
            [promise reject:error];
        } else {
            [promise accept:allLovedSongs];
        }
    }];
    return promise;
}

#pragma mark -

- (RKURLRequestPromise *)lovedSongsStartingAtOffset:(NSUInteger)offset
{
    NSAssert(self.username, @"*** Warning, cannot fetch the loved songs feed without being authenticated.");
	
    NSString *path = [NSString stringWithFormat:@"/user/%@/loved", [_username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:path
                                                             parameters:@{@"results": @50, @"start": @(offset)}];
}

- (RKURLRequestPromise *)lovedSongsOfFriendsFeedStartingAtOffset:(NSUInteger)offset
{
	NSAssert(self.username, @"Cannot fetch the loved songs of friends feed without being authenticated.");
	
    NSString *path = [NSString stringWithFormat:@"/user/%@/feed/love", [_username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:path
                                                             parameters:@{@"results": @50, @"start": @(offset)}];
}

#pragma mark -

- (RKURLRequestPromise *)updateNowPlayingWithSong:(Song *)song duration:(NSTimeInterval)duration
{
	NSParameterAssert(song.name);
	NSParameterAssert(song.artist);
	NSAssert(self.isAuthorized, @"Cannot update now playing status without being authenticated.");
	
	NSString *path = nil;
	if(song.songSource == kSongSourceExfm)
		path = [NSString stringWithFormat:@"/now-playing/%@", [song.sourceIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	else
		path = @"/now-playing";
    
    NSDictionary *parameters = @{ @"title": song.name,
                                  @"artist": song.artist,
                                  @"album": song.album ?: @"",
                                  @"client_id": @"pinna",
                                  @"context": _username };
	
    return [[self.class sharedRequestFactory] POSTRequestPromiseWithPath:path
                                                              parameters:nil
                                                                    body:parameters
                                                                bodyType:kRKRequestFactoryBodyTypeURLParameters];
}

- (RKURLRequestPromise *)scrobbleSong:(Song *)song duration:(NSTimeInterval)duration
{
	NSParameterAssert(song.name);
	NSParameterAssert(song.artist);
	NSAssert(self.isAuthorized, @"Cannot update now playing status without being authenticated.");
	
	NSString *path = nil;
	if(song.songSource == kSongSourceExfm)
		path = [NSString stringWithFormat:@"/scrobble/%@", [song.sourceIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	else
		path = @"/scrobble";
    
    NSDictionary *parameters = @{ @"title": song.name,
                                  @"artist": song.artist,
                                  @"album": song.album ?: @"",
                                  @"client_id": @"pinna",
                                  @"context": _username };
	
    return [[self.class sharedRequestFactory] POSTRequestPromiseWithPath:path
                                                              parameters:nil
                                                                    body:parameters
                                                                bodyType:kRKRequestFactoryBodyTypeURLParameters];
}

#pragma mark - Song Suite

- (RKURLRequestPromise *)songWithID:(NSString *)identifier
{
	NSParameterAssert(identifier);
	
	NSString *path = [NSString stringWithFormat:@"/song/%@", [identifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:path parameters:nil];
}

- (RKURLRequestPromise *)searchSongsWithQuery:(NSString *)query offset:(NSUInteger)offset
{
	NSParameterAssert(query);
	
	NSString *path = [NSString stringWithFormat:@"/song/search/%@", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:path parameters:@{@"results": @50, @"start": @(offset)}];
}

- (RKURLRequestPromise *)loveSongWithID:(NSString *)songID
{
	NSParameterAssert(songID);
	NSAssert(self.isAuthorized, @"Cannot love a song without being authenticated.");
	
	NSString *path = [NSString stringWithFormat:@"/song/%@/love", [songID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    RKURLRequestPromise *requestPromise = [[self.class sharedRequestFactory] POSTRequestPromiseWithPath:path
                                                                                             parameters:nil
                                                                                                   body:@{@"username": _username, @"password": _password}
                                                                                               bodyType:kRKRequestFactoryBodyTypeURLParameters];
#if !TARGET_OS_IPHONE
    requestPromise.postProcessor = RKPostProcessorBlockChain(requestPromise.postProcessor, ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
        [maybeData whenValue:^(id result) {
            NSDictionary *songResult = result[@"song"];
            [self addSongResultToCache:songResult];
        }];
        return maybeData;
    });
#endif /* !TARGET_OS_IPHONE */
    return requestPromise;
}

- (RKURLRequestPromise *)unloveSongWithID:(NSString *)songID
{
	NSParameterAssert(songID);
	NSAssert(self.isAuthorized, @"Cannot unlove a song without being authenticated.");
	
	NSString *path = [NSString stringWithFormat:@"/song/%@/unlove", [songID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    RKURLRequestPromise *requestPromise = [[self.class sharedRequestFactory] POSTRequestPromiseWithPath:path
                                                                                             parameters:nil
                                                                                                   body:@{@"username": _username, @"password": _password}
                                                                                               bodyType:kRKRequestFactoryBodyTypeURLParameters];
#if !TARGET_OS_IPHONE
    requestPromise.postProcessor = RKPostProcessorBlockChain(requestPromise.postProcessor, ^RKPossibility *(RKPossibility *maybeData, RKURLRequestPromise *request) {
        [maybeData whenValue:^(id result) {
            NSDictionary *songResult = result[@"song"];
            [self removeSongWithIDFromCache:songResult[@"id"]];
        }];
        return maybeData;
    });
#endif /* !TARGET_OS_IPHONE */
    return requestPromise;
}

#pragma mark - Explore Suite

- (RKURLRequestPromise *)overallTrendingSongs
{
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:@"/trending" parameters:nil];
}

- (RKURLRequestPromise *)overallTrendingSongsFromOffset:(NSUInteger)offset
{
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:@"/trending" parameters:@{@"results": @50, @"start": @(offset)}];
}

- (RKURLRequestPromise *)trendingSongsWithTag:(NSString *)tag
{
	NSParameterAssert(tag);
	
	NSString *path = [NSString stringWithFormat:@"/trending/tag/%@", [tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:path parameters:nil];
}

- (RKURLRequestPromise *)trendingSongsWithTag:(NSString *)tag offset:(NSUInteger)offset
{
	NSParameterAssert(tag);
	
	NSString *path = [NSString stringWithFormat:@"/trending/tag/%@", [tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    return [[self.class sharedRequestFactory] GETRequestPromiseWithPath:path parameters:@{@"results": @50, @"start": @(offset)}];
}

#pragma mark - Authentication

#pragma mark • To Ignore Untrusted Certificates

//This is probably not the best way to handle this, but, occasionally Ex.fm
//has issues where its server will have an untrusted certificate. We can't
//really bother the user with this, so we pretty much are ignoring the issue
//until we find a better way to handle this.

- (BOOL)request:(RKURLRequestPromise *)sender canHandlerAuthenticateProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)request:(RKURLRequestPromise *)sender handleAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

@end
