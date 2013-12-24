//
//  Pinna.h
//  Pinna
//
//  Created by Peter MacWhinnie on 9/25/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AVPlayer, AVPlayerLayer, AVURLAsset;
@class Song;
@protocol AudioPlayerPulseObserver;

///Posted when an audio player cannot activate shuffle.
RK_EXTERN NSString *const AudioPlayerShuffleModeFailedNotification;

///Posted when an audio player encounters an error during playback.
///
///`userInfo` contains one key, @"error".
RK_EXTERN NSString *const AudioPlayerErrorDidOccurNotification;

///Posted when an audio player has video available.
RK_EXTERN NSString *const AudioPlayerHasVideoNotification;

///Posted when an audio player does not have video.
RK_EXTERN NSString *const AudioPlayerDoesNotHaveVideoNotification;


///The error codes used by AudioPlayer.
enum AudioPlayerErrorCodes {
	///Indicates AudioPlayer could not play a protected file.
	kAudioPlayerCannotPlayProtectedFileErrorCode = 12001,
	
	///Indicates AudioPlayer encountered an error during playback.
	kAudioPlayerPlaybackFailedErrorCode = 12002,
	
	///Indicates AudioPlayer could not start playback on a file.
	kAudioPlayerPlaybackStartFailedErrorCode = 12003,
	
	///Indicates AudioPlayer failed to maintain a shuffle stream.
	kAudioPlayerShuffleFailedErrorCode = 12004,
};

///The error domain of the AudioPlayer class.
RK_EXTERN NSString *const AudioPlayerErrorDomain;

///The corresponding value is a Song which playback failed for.
RK_EXTERN NSString *const AudioPlayerAffectedSongKey;


///The different modes an audio player can operate in.
typedef enum AudioPlayerMode : NSUInteger {
    ///The normal playback mode.
    kAudioPlayerModeNormal = 0,
    
    ///The repeat queue playback mode.
    kAudioPlayerModeRepeatQueue = 1,
    
    ///The repeat one song playback mode.
    kAudioPlayerModeRepeatSong = 2,
} AudioPlayerMode;


///The class responsible for all playback in Pinna.
@interface AudioPlayer : NSObject
{
	/** Internal State **/
	
	///The playback session identifier. Used for broadcasting presence of the player.
	NSString *mSessionID;
	
	///The underlying player.
	AVPlayer *mPlayer;
	
	///The periodic time observer of the player.
	id mPeriodicTimeObserver;
	
	///The asset currently loading in the audio player.
	AVURLAsset *mLoadingSongAsset;
	
	///Whether or not the player is playing.
	BOOL mIsPlaying;
	
	///Whether or not the player is buffering.
	BOOL mIsBuffering;
	
	///Whether or not the audio player is paused.
	BOOL mIsPaused;
	
	///Used to track starting time for songs that don't have a duration.
	NSDate *mStartDate;
	
	///Used to track the starting time for songs that don't have a duration
	///across the bounds of a pause/resume operation.
	double mCurrentTimeBeforePause;
	
	///The play queue of the audio player.
	NSMutableOrderedSet *mPlayQueue;
	
	///The song currently being played.
	Song *mPlayingSong;
	
	///Whether or not the last track had video.
	BOOL mLastTrackHadVideo;
	
	
	///The queue used to load remote artwork.
	dispatch_queue_t mArtworkLoadQueue;
	
	///The song artwork is loading for.
	Song *mSongArtworkIsLoadingFor;
	
	///The remote artwork for the currently playing song.
	NSImage *mCachedArtwork;
	
	
	///The time interval the audio player should stop songs at.
	NSTimeInterval mTimeToStopAt;
	
	///The time observers of the audio player.
	NSPointerArray *mPulseObservers;
	
	
	///The recently played songs as tracked by the audio player in shuffle.
	NSMutableArray *mRecentlyPlayedShuffleSongs;
	
	///The songs known to shuffle mode to be invalid.
	NSMutableSet *mSongsKnownInvalidToShuffle;
	
	///The next song to play in shuffle.
	Song *mNextShuffleSong;
	
	///The source that shuffle should draw songs from.
	NSArray *mShuffleSource;
	
	///The number of silent failures that have occurred with the shuffle mode.
	NSUInteger mSilentFailureCount;
	
	
	/** Properties **/
	
	///The video layer of the player.
	AVPlayerLayer *mPlayerVideoLayer;
	
	NSArray *mSelectedSongsInPlayQueue;
	BOOL mShuffleMode;
}

///Returns the shared Player instance, creating it if it doesn't exist.
+ (AudioPlayer *)sharedAudioPlayer;

#pragma mark - Properties

///The selected songs in the player's play queue.
///This method should be bound to whatever array controller
///is presenting the audio player's play queue array.
@property (nonatomic, copy) NSArray *selectedSongsInPlayQueue;

///The play queue of the Player. Fully KVC compliant.
@property (nonatomic, copy) NSArray *playQueue;

///Adds an array of songs to the play queue, ignoring any duplicate songs.
- (void)addSongsToPlayQueue:(NSArray *)songs;

///Shuffles an array of songs into the play queue, ignoring any duplicate songs.
- (void)shuffleSongsIntoPlayQueue:(NSArray *)songs;

///The song that is currently playing. Mutating this property causes the receiver
///to play whatever value it's set to, or to stop if the value is nil.
@property (nonatomic) Song *playingSong;

#pragma mark -

///Whether or not the Player is playing.
@property (nonatomic, readonly) BOOL isPlaying;

///Whether or not the Player is buffering.
@property (nonatomic, readonly) BOOL isBuffering;

///Whether or not the Player is paused.
@property (nonatomic, readonly) BOOL isPaused;

#pragma mark -

///The volume level of the player.
///
///This property is persistent.
@property float volume;

///The mode of the audio player.
///
///This property is persistent.
@property AudioPlayerMode mode;

///The artwork of the playing song.
@property (readonly, nonatomic) NSImage *artwork;

#pragma mark -

///The layer used to display video. This layer must only be in one host at a time.
@property (readonly, nonatomic) CALayer *playerVideoLayer;

///Whether or not the player has video.
@property (readonly, nonatomic) BOOL playerHasVideo;

#pragma mark - shuffle

///The next radio song to play.
@property (nonatomic) Song *nextShuffleSong;

///The source that shuffle should draw songs from.
///
///Leave this property nil to have AudioPlayer choose songs from `Library.allSongs`.
@property (nonatomic, copy) NSArray *shuffleSource;

///Whether or not the audio player is in shuffle. When in shuffle, the audio
///player ignores the contents of the `playQueue`, and pulls songs out of the library's
///song cache. The algorithm used to pull these songs out is currently random.
@property (nonatomic) BOOL shuffleMode;

#pragma mark - Timing

///The duration of the currently playing song.
@property (readonly) NSTimeInterval duration;

///The player's location within the currently playing song.
@property NSTimeInterval currentTime;

#pragma mark -

///The pulse observers of the audio player.
@property (readonly, copy) NSArray *pulseObservers;

///Adds a pulse observer to the audio player. Audio player *does not* keep a strong reference to observers.
///
///The audio player's pulse ticks at a rate of 1/2 second. Note, a pulse observer may be fired
///at any given time, and as such should not depend on the rate of the pulse being constant.
- (void)addPulseObserver:(id <AudioPlayerPulseObserver>)observer;

///Removes a pulse observer from the audio player.
///
///	\see	`addPulseObserver:`
- (void)removePulseObserver:(id <AudioPlayerPulseObserver>)observer;

#pragma mark - Controlling Playback

///Causes the receiver to play a specified array of songs
///immediately, unpausing playback if it is paused.
///
///This method will add the songs to the end of the play queue if they are not present.
- (void)playSongsImmediately:(NSArray/*of Song*/*)songs;

#pragma mark -

///Causes the receiver to play the next song in its queue.
- (void)playPreviousSongInQueue;

///Causes the receiver to play the previous song in its queue.
- (void)playNextSongInQueue;

///Causes the receiver to toggle between playing and paused.
- (void)pauseOrResume;

///Causes the receiver to completely stop playing.
- (void)stop;

#pragma mark - Playback Control Actions

///Toggles pause-mode on the receiver, starting playback on
///the first song in its play queue if it's not already playing.
- (IBAction)playPause:(id)sender;

///Play the previous song in the receiver's play queue, beeping
///if the receiver is not playing. This method implements iTunes-
///-style back track behaviour. If called twice within 3 seconds,
///or within the first 10 seconds of a song, it will rewind the
///receiver's playing song to its beginning.
- (IBAction)previousTrack:(id)sender;

///Play the next song in the receiver's play queue, beeping if
///the receiver is not currently playing.
- (IBAction)nextTrack:(id)sender;

#pragma mark -

///Shuffle the receiver's play queue, keeping the
///currently playing song at the top of it.
- (IBAction)randomizePlayQueue:(id)sender;

#pragma mark - User Interface Bindings

///Whether or not `previousTrack:` can be used.
@property (nonatomic, readonly) BOOL canPreviousTrack;

///Whether or not `nextTrack:` can be used.
@property (nonatomic, readonly) BOOL canNextTrack;

///Whether or not `playPause:` can currently be used.
@property (nonatomic, readonly) BOOL canPlayPause;

///Whether or not `randomizePlayQueue:` can currently be used.
@property (nonatomic, readonly) BOOL canRandomizePlayQueue;

@end

///A global constant for the shared AudioPlayer instance.
///Not valid until +[AudioPlayer sharedAudioPlayer] has been called.
RK_EXTERN AudioPlayer *Player;

#pragma mark -

@protocol AudioPlayerPulseObserver <NSObject>
@required

///Sent when an audio player has updated its `currentTime` property.
- (void)audioPlayerPulseDidTick:(AudioPlayer *)audioPlayer;

@end
