//
//  ScriptingController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/13/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MainWindow;
@class Library;
@class AudioPlayer;
@class Song;

///The notification posted when Pinna changes it's playing song.
RK_EXTERN NSString *const ScriptingControllerPlayingSongDidChangeNotification;

///The scripting controller is responsible for providing support to JSTalk.
@interface ScriptingController : NSObject
{
	MainWindow *mMainWindow;
	Library *mLibrary;
	AudioPlayer *mAudioPlayer;
}

///Initialize the receiver with a specified main window.
- (id)initWithMainWindow:(MainWindow *)mainWindow;

#pragma mark - Playback

///The playing song of the scripting controller.
@property (nonatomic) Song *playingSong;

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
- (void)addSongToQueue:(Song *)song;

///Insert a song at a given index in the queue.
- (void)insertSong:(Song *)song atIndexInQueue:(NSUInteger)index;

///Remove a song from the queue.
- (void)removeSongFromQueue:(Song *)song;

#pragma mark - Querying the Library

///All of the songs in Pinna.
@property (nonatomic, readonly) NSArray *allSongs;

///Returns the first song matching a given universal identifier.
- (Song *)songWithUniversalIdentifier:(NSString *)universalIdentifier;

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
