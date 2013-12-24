//
//  SongQueryPromise.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 10/3/12.
//
//

#import <RoundaboutKitMac/RKPromise.h>

@class Library;

///The key used for errors from a song query promise that will contain the searched-for songs name.
RK_EXTERN NSString *const SongQueryPromiseSongNameErrorKey;

///The key used for errors from a song query promise that will contain the searched-for songs artist.
RK_EXTERN NSString *const SongQueryPromiseSongArtistErrorKey;

///The SongQueryPromise object represents a promise that can yield a local or remote
///song with a given artist and name. Used for matching songs from external sources.
@interface SongQueryPromise : RKPromise
{
	Library *mLibrary;
	
	NSString *mName;
	NSString *mArtist;
}

///Initialize the receiver with the external identifier of a song.
- (id)initWithIdentifier:(NSString *)identifier;

///Initialize the receiver with a given name and artist.
///
/// \param  name    Required.
/// \param  artist  Required.
///
///This is the designated initializer of the SongQueryPromise class.
- (id)initWithName:(NSString *)name artist:(NSString *)artist;

#pragma mark - Properties

///The name of the song.
@property (copy, readonly) NSString *name;

///The artist of the song.
@property (copy, readonly) NSString *artist;

@end
