//
//  ScriptingController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/13/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "ScriptingController.h"
#import "MainWindow.h"
#import "AudioPlayer.h"
#import "Library.h"
#import "Song.h"

NSString *const ScriptingControllerPlayingSongDidChangeNotification = @"com.roundabout.pinna.playingsongdidchange";

@implementation ScriptingController

- (id)initWithMainWindow:(MainWindow *)mainWindow
{
	if((self = [super init]))
	{
		mMainWindow = mainWindow;
		mLibrary = [Library sharedLibrary];
		mAudioPlayer = [AudioPlayer sharedAudioPlayer];
	}
	
	return self;
}

- (NSString *)description
{
	if(self.isPlaying)
	{
		Song *playingSong = self.playingSong;
		return [NSString stringWithFormat:@"%@ - “%@” by %@", playingSong.name, playingSong.album, playingSong.artist];
	}
	
	return @"Nothing Playing";
}

#pragma mark - Playback

- (void)setPlayingSong:(Song *)playingSong
{
	mAudioPlayer.playingSong = playingSong;
}

- (Song *)playingSong
{
	return mAudioPlayer.playingSong;
}

- (NSData *)playingSongArtwork
{
    return [mAudioPlayer.artwork TIFFRepresentation];
}

- (BOOL)isPlaying
{
	return mAudioPlayer.isPlaying;
}

- (BOOL)isPaused
{
	return mAudioPlayer.isPaused;
}

#pragma mark -

- (void)playPause
{
	[mAudioPlayer playPause:nil];
}

- (void)nextTrack
{
	[mAudioPlayer nextTrack:nil];
}

- (void)previousTrack
{
	[mAudioPlayer previousTrack:nil];
}

- (void)setVolume:(float)volume
{
	if(volume < 0.0)
		volume = 0.0;
	else if(volume > 1.0)
		volume = 1.0;
	
	mAudioPlayer.volume = volume;
}

- (float)volume
{
	return mAudioPlayer.volume;
}

- (void)setShuffleEnabled:(BOOL)shuffleEnabled
{
	if(mAudioPlayer.shuffleMode == shuffleEnabled)
		return;
	
	if(shuffleEnabled)
		[mMainWindow activateShuffleMode:nil];
	else
		[mMainWindow deactivateShuffleMode:nil];
}

- (BOOL)shuffleEnabled
{
	return mAudioPlayer.shuffleMode;
}

#pragma mark - Queue

- (NSArray *)queue
{
	return mAudioPlayer.playQueue;
}

#pragma mark -

- (void)addSongToQueue:(Song *)song
{
	if(!song)
		return;
	
	NSMutableArray *queue = [mAudioPlayer mutableArrayValueForKey:@"playQueue"];
	[queue addObject:song];
}

- (void)insertSong:(Song *)song atIndexInQueue:(NSUInteger)index
{
	if(!song)
		return;
	
	NSMutableArray *queue = [mAudioPlayer mutableArrayValueForKey:@"playQueue"];
	[queue insertObject:song atIndex:index];
}

- (void)removeSongFromQueue:(Song *)song
{
	if(!song)
		return;
	
	NSMutableArray *queue = [mAudioPlayer mutableArrayValueForKey:@"playQueue"];
	[queue removeObject:song];
}

#pragma mark - Querying the Library

- (NSArray *)allSongs
{
	return mLibrary.songs;
}

- (Song *)songWithUniversalIdentifier:(NSString *)universalIdentifier
{
	if(!universalIdentifier)
		return nil;
	
	return RKCollectionFindFirstMatch(mLibrary.songs, ^BOOL(Song *song) {
		return [song.universalIdentifier isEqualToString:universalIdentifier];
	});
}

#pragma mark - Main Window

- (void)setSearchString:(NSString *)searchString
{
	mMainWindow.searchString = searchString;
}

- (NSString *)searchString
{
	return mMainWindow.searchString;
}

#pragma mark -

- (void)browseByPlaylists
{
	[mMainWindow showPlaylistsPane:nil];
}

- (void)browseByArtists
{
	[mMainWindow showArtistsPane:nil];
}

- (void)browseByAlbums
{
	[mMainWindow showAlbumsPane:nil];
}

- (void)browseBySongs
{
	[mMainWindow showSongsPane:nil];
}

- (void)browseByExplore
{
	[mMainWindow showExplorePane:nil];
}

@end
