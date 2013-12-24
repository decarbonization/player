//
//  ExfmSession+CachedSongs.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/12/13.
//
//

#ifndef ExfmSession_CachedSongs_h
#define ExfmSession_CachedSongs_h 1

#import "ExfmSession.h"

///Posted when an Ex.fm session has finished updating its loved songs cache.
RK_EXTERN NSString *const ExfmSessionUpdatedCachedLovedSongsNotification;

///Posted when an Ex.fm session has finished updating its loved songs of friends cache.
RK_EXTERN NSString *const ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification;

///Posted when an Ex.fm session has loaded the cached songs from the user defaults.
RK_EXTERN NSString *const ExfmSessionLoadedCachedSongsNotification;

///Posted when an Ex.fm session has unloaded the cached songs from memory.
RK_EXTERN NSString *const ExfmSessionUnloadedCachedSongsNotification;

///The ExfmSession+CachedSongs category adds the favorites song caching mechanism
///to ExfmSession that is currently used by Pinna for Mac. This category is not
///intended for use in the Pinna-m appliation.
@interface ExfmSession (CachedSongs)

#pragma mark - Lazy Cache Loading

///Load the cached songs from user defaults.
- (void)loadCachedSongsFromUserDefaults;

///Unload the cached songs from memory.
///
///The cached songs array is only unloaded on iOS under low-memory situations.
- (void)unloadCachedSongs;

///Whether or not the cached love songs are loaded into memory.
- (BOOL)areCachedLovedSongsLoaded;

#pragma mark - Updating Cache

///Causes the receiver to update its cached songs.
///
///This method is automatically invoked in the background every 5 minutes.
- (void)updateCachedSongs;

#pragma mark -

///Adds a specified raw song result to the exfm favorites cache.
- (void)addSongResultToCache:(NSDictionary *)songResult;

///Removes a raw song result matching a specified identifier from the exfm favorites cache.
- (void)removeSongWithIDFromCache:(NSString *)identifier;

#pragma mark - Cache Properties

///The loved songs of the current user.
///
///The value of this property is updated in the background every `n` minutes.
@property (readonly) NSArray *cachedLovedSongs;

///Whether or not the cached loved songs are loaded into memory.
@property (readonly) BOOL areCachedLovedSongsLoaded;

///The cached loved songs of friends.
@property (readonly) NSDictionary *cachedFriendLoveActivity;

///The number of new loved songs from friends.
@property NSUInteger numberOfNewFriendLoveActivities;

@end

#endif /* ExfmSession_CachedSongs_h */
