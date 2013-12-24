//
//  Playlist.h
//  Pinna
//
//  Created by Peter MacWhinnie on 12/4/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The different types a playlist can be.
enum PlaylistType {
    ///The playlist contains music purchased in iTunes.
	kPlaylistTypePurchasedMusic = 1,
    
    ///The playlist contains the user's loved songs.
	kPlaylistTypeLovedSongs = 2,
    
    ///The playlist contains the user's friends' loved songs.
    kPlaylistTypeFriendsLovedSongs = 3,
    
    ///The normal type of playlist, simply imported from iTunes with no special markings.
	kPlaylistTypeDefault = 4,
};
typedef NSUInteger PlaylistType;

///Used to represent playlists in the Player Library system.
@interface Playlist : NSObject
{
	NSString *mName;
	NSArray *mSongs;
	PlaylistType mPlaylistType;
}

///Initialize a playlist with a specified title and a specified content array of songs.
///
///You may not use `kPlaylistTypeUserPlaylist` with this initializer.
- (id)initWithName:(NSString *)name songs:(NSArray *)songs playlistType:(PlaylistType)playlistType;

#pragma mark - Properties

///The title of the playlist.
///
///In the case of Playlist objects wrapping UserPlaylist objects,
///the `name` property simply forwards to the wrapped UserPlaylist.
@property (readonly, RK_NONATOMIC_IOSONLY) NSString *name;

///The songs of the playlist.
@property (copy, RK_NONATOMIC_IOSONLY) NSArray *songs;

///The type of the playlist.
@property (readonly, RK_NONATOMIC_IOSONLY) PlaylistType playlistType;

#pragma mark -

///The badge of the playlist.
///
///Not persisted.
@property (copy) NSString *badge;

#pragma mark - Identity

///Returns a predicate suitable for a search UI displaying an array of playlists.
+ (NSPredicate *)searchPredicateForQueryString:(NSString *)queryString;

@end
