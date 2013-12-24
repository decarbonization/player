//
//  ExfmSession.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/19/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Service.h"

@class RKURLRequestPromise;

///The post processor used by the ExfmSession class.
RK_EXTERN RKPostProcessorBlock const kExfmPostProcessor;

///The ExfmSession class encapsulates communication with the Exfm service
///for Roundabout Software applications.
///
///All methods are available in offline mode unless noted otherwise.
@interface ExfmSession : NSObject <Service>

///Returns the default ExfmSession object, creating it if it does not exist.
+ (ExfmSession *)defaultSession;

///Returns the session request operation queue, creating it if it does not exist.
///
///This operation queue is also used to update the cached songs.
+ (NSOperationQueue *)sessionRequestQueue;

///Returns the shared request factory, creating it if it does not already exist.
+ (RKRequestFactory *)sharedRequestFactory;

#pragma mark - Tools

///Returns a boolean indicating whether or not a given email address is valid.
+ (BOOL)isValidEmailAddress:(NSString *)address;

///Returns a boolean indicating whether or not a given username is valid.
+ (BOOL)isValidUsername:(NSString *)username;

///Returns a boolean indicating whether or not a given password is valid.
+ (BOOL)isValidPassword:(NSString *)password;

#pragma mark - Properties

///The username of the session.
@property (copy) NSString *username;

///The password of the session.
@property (copy) NSString *password;

///Whether or not the session is authorized. KVC compliant.
@property (readonly) BOOL isAuthorized;

#pragma mark - User Suite

///Returns a promise to create a new Ex.fm user.
///
///All params are required.
///
///This method requires an internet connection.
- (RKURLRequestPromise *)createUserWithName:(NSString *)name password:(NSString *)password email:(NSString *)email RK_REQUIRE_RESULT_USED;

///Returns a promise to fetch the current user's info.
- (RKURLRequestPromise *)userInfo RK_REQUIRE_RESULT_USED;

///Returns a promise to fetch the current user's info through a `/me` request.
- (RKURLRequestPromise *)me RK_REQUIRE_RESULT_USED;

///Returns a promise to verify a given username and password.
///
///This method should be used to test login credentials.
///
///This method requires an internet connection.
- (RKURLRequestPromise *)verifyUsername:(NSString *)username password:(NSString *)password RK_REQUIRE_RESULT_USED;

#pragma mark -

///Returns a promise to yield all of the user's loved songs.
///
/// \result A promise that will yield an array of exfm song entities on success.
- (RKPromise *)allLovedSongs RK_REQUIRE_RESULT_USED;

///Returns a promise to yield all of the user's friend's loved songs.
///
/// \result A promise that will yield an array of exfm song entities on success.
- (RKPromise *)allLovedSongsOfFriends RK_REQUIRE_RESULT_USED;

#pragma mark -

///Returns a promise to fetch the logged in user's loved songs feed.
- (RKURLRequestPromise *)lovedSongsStartingAtOffset:(NSUInteger)offset RK_REQUIRE_RESULT_USED;

///Returns a promise to fetch the logged in user's friends' loved songs.
///
///This method does not return standard songs.
- (RKURLRequestPromise *)lovedSongsOfFriendsFeedStartingAtOffset:(NSUInteger)offset RK_REQUIRE_RESULT_USED;

#pragma mark - Song Suite

///Returns a promise to lookup a song with a specified identifier.
- (RKURLRequestPromise *)songWithID:(NSString *)identifier RK_REQUIRE_RESULT_USED;

///Returns a promise to search for songs matching a specified query.
- (RKURLRequestPromise *)searchSongsWithQuery:(NSString *)query offset:(NSUInteger)offset RK_REQUIRE_RESULT_USED;

///Returns a promise to love a song with a specified identifier on Ex.fm.
///
///The receiver must be logged in to use this method.
///
///This method requires an internet connection.
- (RKURLRequestPromise *)loveSongWithID:(NSString *)songID RK_REQUIRE_RESULT_USED;

///Returns a promise to love a song with a specified identifier on Ex.fm.
///
///The receiver must be logged in to use this method.
///
///This method requires an internet connection.
- (RKURLRequestPromise *)unloveSongWithID:(NSString *)songID RK_REQUIRE_RESULT_USED;

#pragma mark - Explore Suite

///Returns a promise to lookup the overall trending songs of today.
- (RKURLRequestPromise *)overallTrendingSongs RK_REQUIRE_RESULT_USED;

///Returns a promise to lookup the overall trending songs of today, starting from a given offset.
- (RKURLRequestPromise *)overallTrendingSongsFromOffset:(NSUInteger)offset RK_REQUIRE_RESULT_USED;

///Returns a promise to lookup the trending songs of today with a specified (required) tag.
- (RKURLRequestPromise *)trendingSongsWithTag:(NSString *)tag RK_REQUIRE_RESULT_USED;

///Returns a promise to lookup the trending songs of today with a specified (required) tag, starting from a given offset.
- (RKURLRequestPromise *)trendingSongsWithTag:(NSString *)tag offset:(NSUInteger)offset RK_REQUIRE_RESULT_USED;

@end

#if !TARGET_OS_IPHONE
#   import "ExfmSession+CachedSongs.h"
#endif /* !TARGET_OS_IPHONE */
