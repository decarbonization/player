//
//  Pinna.h
//  PlayKeys
//
//  Created by Kevin MacWhinnie on 5/27/13.
//
//

#import <Foundation/Foundation.h>

@protocol PinnaSong <NSObject>

///The name of the song.
@property (readonly) NSString *name;

///The artist of the song.
@property (readonly) NSString *artist;

///The album of the song.
@property (readonly) NSString *album;

@end

@protocol PinnaScriptingController <NSObject>

#pragma mark - Playback

///The playing song of the scripting controller.
@property (nonatomic) id <PinnaSong> playingSong;

///The playing song's artwork. Always has a value.
@property (nonatomic) NSData *playingSongArtwork;

///Whether or not Pinna is playing.
@property (nonatomic, readonly) BOOL isPlaying;

///Whether or not Pinna is paused.
@property (nonatomic, readonly) BOOL isPaused;

#pragma mark -

///Causes Pinna to play/pause.
- (void)playPause;

///Causes Pinna to advance to the next track.
- (void)nextTrack;

///Causes Pinna to move backwards to the previous track.
- (void)previousTrack;

///The volume of Pinna. A value between {0.0, 1.0}.
@property (nonatomic) float volume;

///Whether or not shuffle is enabled in Pinna.
@property (nonatomic) BOOL shuffleEnabled;

#pragma mark - Queue

///The contents of the play queue. Readonly.
@property (nonatomic, readonly) NSArray *queue;

#pragma mark -

///Add a song to the queue of the queue.
- (void)addSongToQueue:(id <PinnaSong>)song;

///Insert a song at a given index in the queue.
- (void)insertSong:(id <PinnaSong>)song atIndexInQueue:(NSUInteger)index;

///Remove a song from the queue.
- (void)removeSongFromQueue:(id <PinnaSong>)song;

#pragma mark - Querying the Library

///All of the songs in Pinna.
@property (nonatomic, readonly) NSArray *allSongs;

///Returns the first song matching a given universal identifier.
- (id <PinnaSong>)songWithUniversalIdentifier:(NSString *)universalIdentifier;

#pragma mark - Main Window

///The search string of the main window.
@property (nonatomic, copy) NSString *searchString;

#pragma mark -

///Causes the main window to browse by playlists.
- (void)browseByPlaylists;

///Causes the main window to browse by artists.
- (void)browseByArtists;

///Causes the main window to browse by albums.
- (void)browseByAlbums;

///Causes the main window to browse by songs.
- (void)browseBySongs;

///Causes the main window to browse by explore.
- (void)browseByExplore;

@end

@interface Pinna : NSObject

///Returns the shared Pinna object, creating it if it does not already exist.
+ (instancetype)sharedPinna;

#pragma mark - Properties

///Whether or not the Pinna application is running.
@property (nonatomic, readonly) BOOL isRunning;

///The scripting controller of the Pinna application.
///
///This property will be nil if Pinna is not running.
///A new object is vended each time this property is accessed.
@property (nonatomic, readonly) id <PinnaScriptingController> scriptingController;

@end
