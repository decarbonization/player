//
//  Song.h
//  Pinna
//
//  Created by Peter MacWhinnie on 9/24/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The UTI used to represent songs.
extern NSString *const kSongUTI;

///The source track identifier used to identify songs initialized with `-[Song initWithLocation:]`.
extern NSString *const kSongExternalSourceTrackIdentifier;

///The source of a song.
enum SongSource {
	
	///The song was originally from iTunes.
	kSongSourceITunes = 0,
	
	///The song was originally from Ex.fm.
	kSongSourceExfm = 1,
	
	///The song was originally created from a local file.
	kSongSourceLocalFile = 2,
	
};
typedef NSInteger SongSource;

///A Song object.
///
///Song objects cannot be created from Audiobooks.
@interface Song : NSObject <NSCoding, NSPasteboardReading, NSPasteboardWriting>
{
	NSURL *mLocation;
	NSString *mSourceIdentifier;
	NSString *mPregeneratedUniqueIdentifier;
	
	NSString *mName;
	NSString *mArtist;
	NSString *mAlbum;
	NSString *mAlbumArtist;
	NSString *mGenre;
	NSInteger mTrackNumber;
	NSInteger mDiscNumber;
	float mRating;
	
	NSTimeInterval mDuration;
	NSTimeInterval mStartTime;
	NSTimeInterval mStopTime;
	BOOL mIsProtected;
	BOOL mHasVideo;
	BOOL mIsAudioBook;
	BOOL mDisabled;
	BOOL mIsCompilation;
	
	NSDate *mLastPlayed;
	SongSource mSongSource;
	
	NSDictionary *mRemoteArtworkLocations;
}

///Initialize the song using the metadata of the file at the specified `location`.
///
///*Important:* This initializer can return nil.
- (id)initWithLocation:(NSURL *)location;

///Initialize the song using the information contained in a track dictionary.
///
///	\param	track	A track dictionary loaded from either iTunes or Ex.fm. Required.
///	\param	source	The source of the track.
- (id)initWithTrackDictionary:(NSDictionary *)track source:(SongSource)source;

#pragma mark - Properties

///The location of the song.
@property (readonly) NSURL *location;

///The identifier of the track, set if it was created using an iTunes track.
@property (readonly) NSString *sourceIdentifier;

///Returns the unique identifier of the song.
///
///	\see(RKGenerateSongID)
@property (readonly) NSString *uniqueIdentifier;

///The universal identifier of the song.
///
///	\see(RKGenerateSongID)
@property (readonly) NSString *universalIdentifier;

///The short song representation of the Song.
///
///A short song is a serializable, dictionary representation of the core properties
///of a song. A short song can be used to lookup a song quickly in multiple systems
///and is used as an implementation detail in the Pinna platform.
@property (readonly, copy, RK_NONATOMIC_IOSONLY) NSDictionary *shortSong;

#pragma mark -

///The name of the song.
@property (readonly) NSString *name;

///The artist of the song.
@property (readonly) NSString *artist;

///The album of the song.
@property (readonly) NSString *album;

///The album artist of the song.
///
///This field will take on the value of `album` if the source for
///the song does not specify a specifici album artist. When querying
///songs for artist/album display, this property should be preferred
///over the `artist` property.
@property (readonly) NSString *albumArtist;

///The genre of the song.
@property (readonly) NSString *genre;

///The track number of the song.
@property (readonly) NSInteger trackNumber;

///The disc number of the song.
@property (readonly) NSInteger discNumber;

///The rating of the song as specified in iTunes. {0..100}.
///Will be 0 for songs created from MDItem's or file URLs.
@property (readonly) float rating;

#pragma mark -

///The duration of the song.
@property (readonly) NSTimeInterval duration;

///The point in the song that playback should start.
@property (readonly) NSTimeInterval startTime;

///The point in the song that playback should stop.
@property (readonly) NSTimeInterval stopTime;

///Whether or not the Song is protected.
@property (readonly) BOOL isProtected;

///Whether or not the Song has video.
@property (readonly) BOOL hasVideo;

///Whether or not the Song should be skipped when shuffling.
@property (readonly) BOOL disabled;

///Whether or not the Song is a compilation.
@property (readonly) BOOL isCompilation;

#pragma mark -

///The time the track was last played.
@property (copy) NSDate *lastPlayed;

///The source of the song.
@property (readonly) SongSource songSource;

#pragma mark -

///The remote artwork locations of the song.
///
///	\result	A dictionary possibly containing URLs for @"small", @"medium", and @"large" artwork.
///
///This property is not preserved when a Song is archived.
@property (readonly) NSDictionary *remoteArtworkLocations;

#pragma mark - Identity

///Whether or not a song is equal to another song.
- (BOOL)isEqualToSong:(Song *)song;

///Returns a predicate suitable for a search UI displaying an array of songs.
+ (NSPredicate *)searchPredicateForQueryString:(NSString *)queryString;

@end
