//
//  Pinna.m
//  Pinna
//
//  Created by Peter MacWhinnie on 9/25/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "AudioPlayer.h"
#import "Song.h"

#import "AppDelegate.h"
#import "Library.h"
#import "ExfmSession.h"

#import <CoreAudio/CoreAudio.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <QuickLook/QuickLook.h>

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

static NSString *const kNumberOfRecentlyPlayedSongsDefaultsKey = @"AudioPlayer_numberOfRecentlyPlayedSongs";
static NSString *const kVolumeDefaultsKey = @"AudioPlayer_volume";
static NSString *const kModeDefaultsKey = @"AudioPlayer_mode";
static NSString *const kShouldPauseWhenHeadphonesAreUnpluggedDefaultsKey = @"AudioPlayer_shouldPauseWhenHeadphonesAreUnplugged";
static NSString *const kShouldSkipRemoteSongsInShuffleDefaultsKey = @"AudioPlayer_shouldSkipRemoteSongsInShuffle";
NSString *const kAutoSubstituteBadSourcesKey = @"AudioPlayer_autoSubstituteBadSources";

NSString *const AudioPlayerShuffleModeFailedNotification = @"AudioPlayerShuffleModeFailedNotification";
NSString *const AudioPlayerErrorDidOccurNotification = @"AudioPlayerErrorDidOccurNotification";

NSString *const AudioPlayerHasVideoNotification = @"AudioPlayerHasVideoNotification";
NSString *const AudioPlayerDoesNotHaveVideoNotification = @"AudioPlayerDoesNotHaveVideoNotification";

NSString *const AudioPlayerErrorDomain = @"AudioPlayerErrorDomain";
NSString *const AudioPlayerAffectedSongKey = @"AudioPlayerAffectedSongKey";

AudioPlayer *Player = nil;

@interface AudioPlayer ()

- (void)firePulseObservers;

- (void)selectNextShuffleSong;

#pragma mark -

@property io_connect_t sleepPort;

@end

#pragma mark -

@implementation AudioPlayer

+ (AudioPlayer *)sharedAudioPlayer
{
	static dispatch_once_t creationPredicate = 0;
	dispatch_once(&creationPredicate, ^{
		Player = [AudioPlayer new];
	});
	
	return Player;
}

#pragma mark - AVPlayer Lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initializePlayer
{
	if(mPlayer)
		return;
	
	mPlayer = [AVPlayer new];
	mPlayer.actionAtItemEnd = AVPlayerActionAtItemEndPause;
	mPlayer.volume = RKGetPersistentFloat(kVolumeDefaultsKey);
	
	__block AudioPlayer *me = self;
	mPeriodicTimeObserver = [mPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
		if(me->mTimeToStopAt && (me.currentTime >= me->mTimeToStopAt))
		{
			[me playNextSongInQueue];
		}
		else
		{
			[me firePulseObservers];
		}
	}];
	
	mPlayerVideoLayer.player = mPlayer;
	
	[self willChangeValueForKey:@"isBuffering"];
	mIsBuffering = NO;
	[self didChangeValueForKey:@"isBuffering"];
}

- (void)teardownPlayer
{
	if(!mPlayer)
		return;
	
	[mPlayer pause];
	
	[mLoadingSongAsset cancelLoading];
	mLoadingSongAsset = nil;
	
	[mPlayer.currentItem removeObserver:self forKeyPath:@"status"];
	[mPlayer replaceCurrentItemWithPlayerItem:nil];
	[mPlayer removeTimeObserver:mPeriodicTimeObserver];
	
	mPlayerVideoLayer.player = nil;
	mPlayer = nil;
}

#pragma mark - PlayerKit Compatibility

static CFStringRef const PKAudioPlayerDidBroadcastPresenceNotification = CFSTR("com.roundabout.PKAudioPlayerDidBroadcastPresenceNotification");

static void PKAudioPlayerBroadcastPresence(CFStringRef sessionID)
{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), 
										 PKAudioPlayerDidBroadcastPresenceNotification, 
										 sessionID, 
										 NULL, 
										 true);
}

static void PKAudioPlayerDidBroadcastPresence(CFNotificationCenterRef center, 
											  void *observer, 
											  CFStringRef name, 
											  const void *object, 
											  CFDictionaryRef userInfo)
{
	AudioPlayer *self = (__bridge AudioPlayer *)observer;
	
	if(CFEqual((__bridge CFStringRef)(self->mSessionID), object))
		return;
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		if(!self.isPaused)
			[self pauseOrResume];
	}];
}

#pragma mark - Callbacks

///The different possible output destinations that can be returned by GetAudioOutputDestination.
typedef enum OutputDestination {
    ///PKAudioPlayer does not know where it is sending audio.
    kOutputDestinationUnknown = 0,
    
    ///PKAudioPlayer is sending audio to headphones connected to the computer.
    kOutputDestinationHeadphones = 'hdpn',
    
    ///PKAudioPlayer is sending audio to the computer's internal speakers.
    kOutputDestinationInternalSpeakers = 'ispk',
} OutputDestination;

//Derived From <http://vgable.com/blog/2008/09/11/detecting-if-headphones-are-plugged-in/>
static OutputDestination GetAudioOutputDestination()
{
	OSStatus error = noErr;
	UInt32 dataSize = 0;
	
	
	//Get the default output device
	AudioObjectPropertyAddress outputDeviceAddress = {kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal};
	AudioDeviceID outputDevice = 0;
	dataSize = sizeof(outputDevice);
	error = AudioObjectGetPropertyData(/*inObjectID:*/ kAudioObjectSystemObject, 
									   /*inAddress:*/ &outputDeviceAddress, 
									   /*inQualifierDataSize:*/ 0, 
									   /*inQualifierData:*/ NULL, 
									   /*ioDataSize:*/ &dataSize, 
									   /*outData:*/ &outputDevice);
	if(error != noErr)
	{
		return kOutputDestinationUnknown;
	}
	
	
	//Get the data source for the output device
	AudioObjectPropertyAddress dataSourceAddress = {kAudioDevicePropertyDataSource, kAudioDevicePropertyScopeOutput};
	UInt32 dataSource = 0;
	dataSize = sizeof(dataSource);
	error = AudioObjectGetPropertyData(/*inObjectID:*/ outputDevice, 
									   /*inAddress:*/ &dataSourceAddress, 
									   /*inQualifierDataSize:*/ 0, 
									   /*inQualifierData:*/ NULL, 
									   /*ioDataSize:*/ &dataSize, 
									   /*outData:*/ &dataSource);
	if(error != noErr)
	{
		return kOutputDestinationUnknown;
	}
	
	return (OutputDestination)(dataSource);
}

static OSStatus DefaultAudioDeviceDidChangeListenerProc(AudioObjectID objectID, UInt32 numberAddresses, const AudioObjectPropertyAddress inAddresses[], void *userData)
{
	AudioPlayer *self = (__bridge AudioPlayer *)userData;
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		if(GetAudioOutputDestination() != kOutputDestinationHeadphones)
		{
			if(RK_FLAG_IS_SET([NSEvent modifierFlags], NSAlternateKeyMask) ||
			   !RKGetPersistentBool(kShouldPauseWhenHeadphonesAreUnpluggedDefaultsKey))
			{
				return;
			}
			
			if(!self.isPaused)
				[self pauseOrResume];
		}
	}];
	
	return noErr;
}

//From <http://developer.apple.com/library/mac/#qa/qa1340/_index.html>
static void SystemSleepCallback(void *refCon, io_service_t service, natural_t messageType, void * messageArgument)
{
    AudioPlayer *self = (__bridge AudioPlayer *)refCon;
    
    switch (messageType)
    {
        case kIOMessageCanSystemSleep:
            if(self.isPlaying)
                IOCancelPowerChange(self.sleepPort, (long)messageArgument);
            else
                IOAllowPowerChange(self.sleepPort, (long)messageArgument);
            
            break;
            
        case kIOMessageSystemWillSleep:
            IOAllowPowerChange(self.sleepPort, (long)messageArgument);
            
            if(self.isPlaying && !self.isPaused)
                [self pauseOrResume];
            
            break;
            
        default:
            break;
            
    }
}

#pragma mark -

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		[self playNextSongInQueue];
	}];
}

#pragma mark -

- (void)handlePlayerError:(NSError *)playbackError forSong:(Song *)song wasDuringPlayback:(BOOL)wasDuringPlayback
{
    //This forces synchronization with the code in `-setPlayingSong:`
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		if(mSilentFailureCount >= 5)
		{
			if(mShuffleMode)
			{
				self.shuffleMode = NO;
				
				[[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerShuffleModeFailedNotification object:self];
				
				NSError *error = [NSError errorWithDomain:AudioPlayerErrorDomain
													 code:kAudioPlayerShuffleFailedErrorCode
												 userInfo:@{NSLocalizedDescriptionKey: @"Pinna's shuffle mode could not find anything in your library it was able to play.", NSUnderlyingErrorKey: playbackError, AudioPlayerAffectedSongKey: mPlayingSong}];
				[[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerErrorDidOccurNotification
																	object:self
																  userInfo:@{@"error": error}];
			}
			else
			{
				NSError *error = [NSError errorWithDomain:AudioPlayerErrorDomain
													 code:kAudioPlayerPlaybackFailedErrorCode
												 userInfo:@{NSLocalizedDescriptionKey: @"Pinna encountered an error during playback", NSUnderlyingErrorKey: playbackError, AudioPlayerAffectedSongKey: mPlayingSong}];
				[[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerErrorDidOccurNotification
																	object:self
																  userInfo:@{@"error": error}];
			}
			
			[self stop];
		}
		else
		{
			NSLog(@"Song (%@) could not be played, skipping.", mPlayingSong.name);
			
			if(mShuffleMode)
			{
				//Blitz the next radio song to avoid an infinite loop.
				self.nextShuffleSong = nil;
				
				[self selectNextShuffleSong];
				[self playNextSongInQueue];
			}
			else
			{
				Song *playingSong = self.playingSong;
				
				[self playNextSongInQueue];
				
                if(wasDuringPlayback)
                {
                    NSError *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                                         code:kAudioPlayerPlaybackFailedErrorCode
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Pinna encountered an error during playback", NSUnderlyingErrorKey: playbackError, AudioPlayerAffectedSongKey: playingSong}];
                    [[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerErrorDidOccurNotification
                                                                        object:self
                                                                      userInfo:@{@"error": error}];
                }
                else
                {
                    NSError *error = [NSError errorWithDomain:AudioPlayerErrorDomain
                                                         code:kAudioPlayerPlaybackStartFailedErrorCode
                                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Pinna Cannot Play “%@”", mPlayingSong.name ?: @"(Name Missing)"], NSUnderlyingErrorKey: playbackError, AudioPlayerAffectedSongKey: song}];
                    [[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerErrorDidOccurNotification
                                                                        object:self
                                                                      userInfo:@{@"error": error}];
                }
			}
		}
        
        if(!wasDuringPlayback && !mShuffleMode)
        {
            NSUInteger indexOfFailedSong = [mPlayQueue indexOfObject:song];
            if(indexOfFailedSong != NSNotFound)
                [[self mutableArrayValueForKey:@"playQueue"] removeObjectAtIndex:indexOfFailedSong];
        }
	}];
}

- (BOOL)isMissingFileError:(NSError *)playbackError
{
    if([playbackError.domain isEqualToString:NSURLErrorDomain])
        return (playbackError.code == NSURLErrorFileDoesNotExist ||
                playbackError.code == NSURLErrorNoPermissionsToReadFile);
    
    if([playbackError.domain isEqualToString:NSCocoaErrorDomain])
        return (playbackError.code >= NSFileNoSuchFileError &&
                playbackError.code <= NSFileReadNoSuchFileError);
    
    return NO;
}

#pragma mark -

- (void)playerEncounteredErrorDuringPlayback:(NSError *)playbackError
{
	mSilentFailureCount++;
	
	[mSongsKnownInvalidToShuffle addObject:mPlayingSong];
	
	[self handlePlayerError:playbackError forSong:mPlayingSong wasDuringPlayback:YES];
}

- (void)playerEncounteredErrorAtBeginningOfPlayback:(NSError *)playbackError forSong:(Song *)song
{
	mSilentFailureCount++;
	
	[mSongsKnownInvalidToShuffle addObject:song];
	
    //We attempt to substitute bad sources automatically.
    if(RKGetPersistentBool(kAutoSubstituteBadSourcesKey) &&
       !song.hasVideo && [self isMissingFileError:playbackError])
    {
        NSString *searchQuery = [NSString stringWithFormat:@"%@ %@", song.artist, song.name];
        RKPromise *replacementSongSearch = [[ExfmSession defaultSession] searchSongsWithQuery:searchQuery offset:0];
        [replacementSongSearch then:^(NSDictionary *response) {
            //The user has skipped the playing song.
            if(![song isEqualToSong:mPlayingSong])
                return;
            
            NSArray *unweightedSongs = response[@"songs"];
            NSArray *songs = [unweightedSongs sortedArrayUsingDescriptors:@[
                [NSSortDescriptor sortDescriptorWithKey:@"last_loved" ascending:NO],
            ]];
            NSDictionary *songResult = RKCollectionFindFirstMatch(songs, ^BOOL(NSDictionary *songResult) {
                NSString *title = RKFilterOutNSNull(songResult[@"title"]);
                NSString *artist = RKFilterOutNSNull(songResult[@"artist"]);
                NSString *identifier = RKFilterOutNSNull(songResult[@"id"]);
                return ([[title lowercaseString] hasPrefix:[song.name lowercaseString]] &&
                        [[artist lowercaseString] hasPrefix:[song.artist lowercaseString]] &&
                        ![song.sourceIdentifier isEqualToString:identifier]);
            });
            
            if(songResult)
            {
                Song *replacementSong = [[Song alloc] initWithTrackDictionary:songResult source:kSongSourceExfm];
                NSUInteger indexOfFailedSong = [mPlayQueue indexOfObject:song];
                if(indexOfFailedSong != NSNotFound)
                    [[self mutableArrayValueForKey:@"playQueue"] replaceObjectAtIndex:indexOfFailedSong
                                                                           withObject:replacementSong];
                
                self.playingSong = replacementSong;
            }
            else
            {
                [self handlePlayerError:playbackError forSong:song wasDuringPlayback:NO];
            }
        } otherwise:^(NSError *error) {
            [self handlePlayerError:playbackError forSong:song wasDuringPlayback:NO];
        }];
    }
    else
    {
        [self handlePlayerError:playbackError forSong:song wasDuringPlayback:NO];
    }
}

#pragma mark -

- (void)playerIsReady
{
	if(mPlayingSong.startTime)
		[mPlayer seekToTime:CMTimeMakeWithSeconds(mPlayingSong.startTime, 1)];
	
	if(!mIsPaused)
	{
		mCurrentTimeBeforePause = 0.0;
		mStartDate = [NSDate date];
		
		[mPlayer play];
	}
	
	[self willChangeValueForKey:@"isBuffering"];
	mIsBuffering = NO;
	[self didChangeValueForKey:@"isBuffering"];
	
	mSilentFailureCount = 0;
	
	BOOL hasVideo = self.playerHasVideo;
	if(hasVideo != mLastTrackHadVideo)
	{
		if(hasVideo)
			[[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerHasVideoNotification object:self];
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerDoesNotHaveVideoNotification object:self];
	}
	
	mLastTrackHadVideo = hasVideo;
	
	//For compatibility with PlayerKit-based versions of Pinna.
	//Note, this is broadcasting substantially more frequently
	//than a PlayerKit-backed player would be.
	PKAudioPlayerBroadcastPresence((__bridge CFStringRef)mSessionID);
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		if(object == mPlayer.currentItem && [keyPath isEqualToString:@"status"])
		{
			if(mPlayer.currentItem.status == AVPlayerStatusFailed)
			{
				NSError *error = mPlayer.currentItem.error;
				
				//Reinitialize the internal player,
				//it can't be reused once an error
				//has occurred.
				[self teardownPlayer];
				
				[self willChangeValueForKey:@"isBuffering"];
				mIsBuffering = NO;
				[self didChangeValueForKey:@"isBuffering"];
				
				[self initializePlayer];
				
				if(mPlayer.rate != 0.0)
				{
					[self playerEncounteredErrorDuringPlayback:error];
				}
				else
				{
					[self playerEncounteredErrorAtBeginningOfPlayback:error forSong:mPlayingSong];
				}
			}
			else
			{
				[self playerIsReady];
			}
		}
	}];
}

#pragma mark -

- (id)init
{
	if((self = [super init]))
	{
		//We observe changes to the default output device so we can
		//pause playback when a user unplugs headphones, if requested.
		AudioObjectPropertyAddress address = {
			.mSelector = kAudioHardwarePropertyDefaultOutputDevice, 
			.mScope = kAudioObjectPropertyScopeGlobal, 
			.mElement = 0
		};
		OSStatus error = AudioObjectAddPropertyListener(kAudioObjectSystemObject, //in audioObjectID
														&address, //in propertyAddressPtr
														&DefaultAudioDeviceDidChangeListenerProc, //in listenerCallbackProc
														(__bridge void *)self); //in listenerCallbackProcUserData
		NSAssert((error == noErr), @"AudioObjectAddPropertyListener failed. Error %d.", error);
		
        //This is only necessary because of Mac laptops from 2012 onward
        //are much more aggressive about going to sleep when the system
        //goes idle. This allows us to prevent sleep if we're in the
        //process of buffering a new streaming song.
        IONotificationPortRef notificationPort;
        io_object_t sleepNotifier;
        self.sleepPort = IORegisterForSystemPower((__bridge void *)self, &notificationPort, &SystemSleepCallback, &sleepNotifier);
        NSAssert(self.sleepPort != 0, @"Could not register for system power notifications");
        
        CFRunLoopAddSource(CFRunLoopGetMain(), IONotificationPortGetRunLoopSource(notificationPort), kCFRunLoopCommonModes);
        
		//For compatibility with PlayerKit.
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        mSessionID = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
        CFRelease(uuid);
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), 
										(__bridge void *)self, 
										&PKAudioPlayerDidBroadcastPresence, 
										PKAudioPlayerDidBroadcastPresenceNotification, 
										NULL, 
										CFNotificationSuspensionBehaviorDeliverImmediately);
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(playerItemDidPlayToEndTime:) 
													 name:AVPlayerItemDidPlayToEndTimeNotification 
												   object:nil];
		
		mPlayQueue = [NSMutableOrderedSet new];
		mPulseObservers = [NSPointerArray pointerArrayWithWeakObjects];
		
		mRecentlyPlayedShuffleSongs = [NSMutableArray new];
		mSongsKnownInvalidToShuffle = [NSMutableSet new];
		mShuffleMode = NO;
		
		mArtworkLoadQueue = dispatch_queue_create("com.roundabout.pinna.AudioPlayer.mArtworkLoadQueue", NULL);
		
		mPlayerVideoLayer = [AVPlayerLayer layer];
		mPlayerVideoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
		
		[self initializePlayer];
		
		NSData *archivedSongs = RKGetPersistentObject(@"AudioPlayer_playQueue");
		if(archivedSongs)
		{
			NSArray *songs = [NSKeyedUnarchiver unarchiveObjectWithData:archivedSongs];
			[mPlayQueue addObjectsFromArray:songs];
		}
	}
	
	return self;
}

#pragma mark - Properties

@synthesize selectedSongsInPlayQueue = mSelectedSongsInPlayQueue;

#pragma mark -

- (void)saveQueue
{
	NSData *archivedSongs = [NSKeyedArchiver archivedDataWithRootObject:[mPlayQueue array]];
	RKSetPersistentObject(@"AudioPlayer_playQueue", archivedSongs);
}

- (void)insertPlayQueue:(NSArray *)songs atIndexes:(NSIndexSet *)indexes
{
	[mPlayQueue insertObjects:songs atIndexes:indexes];
	
	[self saveQueue];
}

- (void)removePlayQueueAtIndexes:(NSIndexSet *)indexes
{
	[mPlayQueue removeObjectsAtIndexes:indexes];
	
	[self saveQueue];
}

- (void)replacePlayQueueAtIndexes:(NSIndexSet *)indexes withPlayQueue:(NSArray *)songs
{
	[mPlayQueue replaceObjectsAtIndexes:indexes withObjects:songs];
	
	[self saveQueue];
}

- (void)setPlayQueue:(NSArray *)playQueue
{
	[mPlayQueue removeAllObjects];
	[mPlayQueue addObjectsFromArray:playQueue];
	
	[self saveQueue];
}

- (NSArray *)playQueue
{
	return [mPlayQueue array];
}

#pragma mark -

- (void)addSongsToPlayQueue:(NSArray *)songs
{
	if([songs count] == 0)
		return;
	
	if(mShuffleMode)
		self.shuffleMode = NO;
	
	NSMutableArray *playQueue = [self mutableArrayValueForKey:@"playQueue"];
	[playQueue addObjectsFromArray:RKCollectionFilterToArray(songs, ^BOOL(id value) {
		return ![mPlayQueue containsObject:value];
	})];
}

- (void)shuffleSongsIntoPlayQueue:(NSArray *)songs
{
	if([songs count] == 0)
		return;
	
	if([songs count] == 1)
	{
		[self playSongsImmediately:songs];
		return;
	}
	
	NSMutableArray *nonduplicateSongs = [RKCollectionFilterToArray(songs, ^BOOL(Song *s) {
		return ![mPlayQueue containsObject:s];
	}) mutableCopy];
	
	NSMutableArray *playQueue = [self mutableArrayValueForKey:@"playQueue"];
	while ([nonduplicateSongs count] > 0)
	{
		NSUInteger randomIndex = arc4random() % [nonduplicateSongs count];
		[playQueue addObject:[nonduplicateSongs objectAtIndex:randomIndex]];
		[nonduplicateSongs removeObjectAtIndex:randomIndex];
	}
}

#pragma mark -

- (void)replaceCurrentPlayerItem:(AVPlayerItem *)newItem
{
	AVPlayerItem *currentItem = mPlayer.currentItem;
	[currentItem removeObserver:self forKeyPath:@"status"];
	
	if(newItem.status == AVPlayerStatusFailed)
	{
		[mPlayer replaceCurrentItemWithPlayerItem:nil];
	}
	else
	{
		[newItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
		[mPlayer replaceCurrentItemWithPlayerItem:newItem];
	}
}

- (void)setPlayingSong:(Song *)playingSong
{
	if(playingSong.isProtected && playingSong.hasVideo)
	{
		mPlayingSong = playingSong;
		
		NSError *error = [NSError errorWithDomain:AudioPlayerErrorDomain
											 code:kAudioPlayerCannotPlayProtectedFileErrorCode
										 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Pinna Cannot Play The Protected Video “%@”", playingSong.name ?: @"(Name Missing)"], AudioPlayerAffectedSongKey: playingSong}];
		
		[self playerEncounteredErrorAtBeginningOfPlayback:error forSong:playingSong];
		
		return;
	}
	
	if(!playingSong)
	{
		[self stop];
		return;
	}
	
	NSMutableArray *playQueue = [self mutableArrayValueForKey:@"playQueue"];
	if(!mShuffleMode && ![playQueue containsObject:playingSong])
		[playQueue addObject:playingSong];
	
	BOOL lastAssetHadNoDuration = NO;
	if(self.isPlaying)
	{
		if(mPlayer.currentItem)
			lastAssetHadNoDuration = (mPlayer.currentItem.duration.timescale == 0);
		
		[mPlayer pause];
		[self replaceCurrentPlayerItem:nil];
	}
	
	[mLoadingSongAsset cancelLoading];
	AVURLAsset *songAsset = [AVURLAsset assetWithURL:playingSong.location];
	mLoadingSongAsset = songAsset;
	[songAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
		if(![mPlayingSong.location isEqual:playingSong.location] && mPlayer.rate != 0.0)
			return;
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			if(songAsset != mLoadingSongAsset || mPlayer.rate != 0.0 || mPlayingSong == nil)
				return;
			
			mLoadingSongAsset = nil;
			
			if(songAsset.playable)
			{
				//For undocumented, unknown reasons, you cannot load a song without
				//a duration after you've loaded one that has one. Therefore, we have
				//to reinitialize the audio player to ensure playback will continue
				//as the user expects.
				if(lastAssetHadNoDuration)
				{
					[self teardownPlayer];
					[self initializePlayer];
				}
				
				AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:songAsset];
				[self replaceCurrentPlayerItem:playerItem];
			}
			else
			{
				NSError *error = nil;
				[songAsset statusOfValueForKey:@"tracks" error:&error];
				[self playerEncounteredErrorAtBeginningOfPlayback:error forSong:playingSong];
			}
		}];
	}];
	
	[self willChangeValueForKey:@"isBuffering"];
	mIsBuffering = YES;
	[self didChangeValueForKey:@"isBuffering"];
	
	mTimeToStopAt = playingSong.stopTime;
	
	mPlayingSong = playingSong;
	
	NSInteger numberOfRecentlyPlayedSongs = RKGetPersistentInteger(kNumberOfRecentlyPlayedSongsDefaultsKey);
	if(numberOfRecentlyPlayedSongs != -1)
	{
		NSUInteger indexOfPlayingSong = [playQueue indexOfObject:mPlayingSong];
		if(numberOfRecentlyPlayedSongs == 0)
		{
			[playQueue removeObjectsInRange:NSMakeRange(0, indexOfPlayingSong)];
		}
		else if(indexOfPlayingSong > numberOfRecentlyPlayedSongs)
		{
			[playQueue removeObjectsInRange:NSMakeRange(0, indexOfPlayingSong - numberOfRecentlyPlayedSongs)];
		}
	}
	
	mPlayingSong.lastPlayed = [NSDate date];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		//Fire each of the pulse observers. We do this
		//specifically so the pulse observer in MainWindow
		//will properly update the scrubbing bar at the
		//beginning of songs, preventing a visual disconnect.
		[self firePulseObservers];
	}];
	
	mCachedArtwork = nil;
}

- (Song *)playingSong
{
	return mPlayingSong;
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingIsPlaying
{
	return [NSSet setWithObjects:@"playingSong", @"isBuffering", nil];
}

- (BOOL)isPlaying
{
	return mIsBuffering || ((mPlayer.currentItem != nil) || mIsPaused);
}

@synthesize isBuffering = mIsBuffering;

@synthesize isPaused = mIsPaused;

#pragma mark -

- (void)setVolume:(float)volume
{
	mPlayer.volume = volume;
	
	RKSetPersistentFloat(kVolumeDefaultsKey, volume);
}

- (float)volume
{
	return RKGetPersistentFloat(kVolumeDefaultsKey);
}

#pragma mark -

- (void)setMode:(AudioPlayerMode)mode
{
    RKSetPersistentInteger(kModeDefaultsKey, mode);
}

- (AudioPlayerMode)mode
{
    return RKGetPersistentInteger(kModeDefaultsKey);
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingArtwork
{
	return [NSSet setWithObjects:@"playingSong", nil];
}

- (NSImage *)artwork
{
	if(mCachedArtwork)
	{
		return mCachedArtwork;
	}
    else if(mPlayingSong.remoteArtworkLocations[@"large"])
	{
		if(mSongArtworkIsLoadingFor != mPlayingSong)
		{
			NSURL *largeArtworkURL = mPlayingSong.remoteArtworkLocations[@"large"];
			
			Song *playingSongAtTimeOfRemoteLoadOperation = mPlayingSong;
			mSongArtworkIsLoadingFor = mPlayingSong;
			dispatch_async(mArtworkLoadQueue, ^{
				NSImage *largeArtwork = [[NSImage alloc] initWithContentsOfURL:largeArtworkURL];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					if(![playingSongAtTimeOfRemoteLoadOperation isEqualTo:mPlayingSong])
						return;
					
					[self willChangeValueForKey:@"artwork"];
					mCachedArtwork = largeArtwork;
					[self didChangeValueForKey:@"artwork"];
					
					mSongArtworkIsLoadingFor = nil;
				});
			});
		}
	}
	else
	{
		if(mSongArtworkIsLoadingFor != mPlayingSong)
		{
			Song *playingSongAtTimeOfRemoteLoadOperation = mPlayingSong;
			mSongArtworkIsLoadingFor = mPlayingSong;
			dispatch_async(mArtworkLoadQueue, ^{
				CGImageRef thumbnail = QLThumbnailImageCreate(kCFAllocatorDefault, 
															  (__bridge CFURLRef)(mPlayingSong.location), 
															  CGSizeMake(512.0, 512.0), 
															  NULL);
				if(thumbnail)
				{
					NSBitmapImageRep *artworkImageRep = [[NSBitmapImageRep alloc] initWithCGImage:thumbnail];
					NSImage *artworkImage = [[NSImage alloc] initWithSize:[artworkImageRep size]];
					[artworkImage addRepresentation:artworkImageRep];
					CGImageRelease(thumbnail);
					dispatch_async(dispatch_get_main_queue(), ^{
						if(![playingSongAtTimeOfRemoteLoadOperation isEqualTo:mPlayingSong])
							return;
						
						[self willChangeValueForKey:@"artwork"];
						mCachedArtwork = artworkImage;
						[self didChangeValueForKey:@"artwork"];
						
						mSongArtworkIsLoadingFor = nil;
					});
				}
			});
		}
	}
	
	return [NSImage imageNamed:@"NoArtwork"];
}

#pragma mark -

@synthesize playerVideoLayer = mPlayerVideoLayer;

- (BOOL)playerHasVideo
{
	return RKCollectionDoesAnyValueMatch(mPlayer.currentItem.tracks, ^BOOL(AVPlayerItemTrack *itemTrack) {
		AVAssetTrack *track = itemTrack.assetTrack;
		return [track.mediaType isEqualToString:AVMediaTypeVideo];
	});
}

#pragma mark - Radio Mode

- (NSUInteger)numberOfRecentlyPlayedSongsToTrackForShuffleMode
{
	NSArray *songs = self.shuffleSource ?: [Library sharedLibrary].songs;
	NSUInteger songsCount = [songs count];
	if(songsCount < 5)
		return 0;
	
    return floor(songsCount * 0.25);
}

- (BOOL)shouldSkipSongInShuffle:(Song *)song
{
	BOOL shouldSkipRemoteSongsInShuffle = RKGetPersistentBool(kShouldSkipRemoteSongsInShuffleDefaultsKey);
	BOOL basicSkipConditions = (song.hasVideo ||
                                song.disabled ||
                                [mSongsKnownInvalidToShuffle containsObject:song]);
    BOOL isRemoteSongToSkip = ((shouldSkipRemoteSongsInShuffle ||
                                ![RKConnectivityManager defaultInternetConnectivityManager].isConnected)
                               && ![song.location isFileURL]);
	return (basicSkipConditions || isRemoteSongToSkip);
}

- (void)selectNextShuffleSong
{
	NSArray *songs = self.shuffleSource ?: [Library sharedLibrary].songs;
	NSUInteger songsCount = [songs count];
	
	if(songsCount == 0)
	{
		mNextShuffleSong = nil;
		return;
	}
	
	Song *newSong = nil;
	do
	{
		newSong = [songs objectAtIndex:arc4random() % [songs count]];
	}
	while (((songsCount >= [self numberOfRecentlyPlayedSongsToTrackForShuffleMode]) &&
			[mRecentlyPlayedShuffleSongs containsObject:newSong]) || 
		   [self shouldSkipSongInShuffle:newSong]);
	
	self.nextShuffleSong = newSong;
}

#pragma mark -

@synthesize nextShuffleSong = mNextShuffleSong;
@synthesize shuffleSource = mShuffleSource;

- (void)setShuffleMode:(BOOL)shuffleMode
{
	if(mShuffleMode == shuffleMode)
		return;
	
	mShuffleMode = shuffleMode;
	
	if(shuffleMode)
	{
		[mRecentlyPlayedShuffleSongs removeAllObjects];
		if(mPlayingSong)
			[mRecentlyPlayedShuffleSongs addObject:mPlayingSong];
		
		[self selectNextShuffleSong];
	}
	
}

- (BOOL)shuffleMode
{
	return mShuffleMode;
}

#pragma mark - Timing

+ (NSSet *)keyPathsForValuesAffectingDuration
{
	return [NSSet setWithObjects:@"playingSong", @"isBuffering", nil];
}

- (NSTimeInterval)duration
{
	if(mIsBuffering || !mPlayer.currentItem)
		return 0.0;
	
	CMTime time = mPlayer.currentItem.duration;
	if(time.timescale == 0.0)
		return 0.0;
	
	return time.value / time.timescale;
}

+ (NSSet *)keyPathsForValuesAffectingCurrentTime
{
	return [NSSet setWithObjects:@"playingSong", @"isBuffering", nil];
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
	if((!self.isPlaying && !self.isPaused) || self.duration == 0.0)
		return;
	
	[mPlayer seekToTime:CMTimeMakeWithSeconds(currentTime, 1)];
	
	[self firePulseObservers];
}

- (NSTimeInterval)currentTime
{
	if(mIsBuffering || !mPlayer.currentItem)
		return 0.0;
	
	if(self.duration == 0.0 && !mIsPaused)
	{
		return [[NSDate date] timeIntervalSinceDate:mStartDate];
	}
	
	CMTime time = mPlayer.currentTime;
	return time.value / time.timescale;
}

#pragma mark -

- (void)firePulseObservers
{
	for (id <AudioPlayerPulseObserver> observer in mPulseObservers)
		[observer audioPlayerPulseDidTick:self];
}

- (NSArray *)pulseObservers
{
	return [mPulseObservers allObjects];
}

- (void)addPulseObserver:(id <AudioPlayerPulseObserver>)observer
{
	NSParameterAssert(observer);
	
	[mPulseObservers addPointer:(__bridge void *)observer];
}

- (void)removePulseObserver:(id <AudioPlayerPulseObserver>)observer
{
	NSParameterAssert(observer);
	
	NSUInteger index = 0;
	for (id <AudioPlayerPulseObserver> possibleMatch in mPulseObservers)
	{
		if([possibleMatch isEqual:observer])
		{
			[mPulseObservers removePointerAtIndex:index];
			break;
		}
		
		index++;
	}
}

#pragma mark - Controlling Playback

- (void)playSongsImmediately:(NSArray/*of Song*/*)songs
{
	if([songs count] == 0)
	{
		[self stop];
		return;
	}
	
	if(self.shuffleMode)
		self.shuffleMode = NO;
	
	[self addSongsToPlayQueue:songs];
	
	[self willChangeValueForKey:@"isPaused"];
	mIsPaused = NO;
	[self didChangeValueForKey:@"isPaused"];
	
	[self willChangeValueForKey:@"isBuffering"];
	mIsBuffering = YES;
	[self didChangeValueForKey:@"isBuffering"];
	
	self.playingSong = [songs objectAtIndex:0];
}

- (void)playPreviousSongInQueue
{
	if(mShuffleMode)
	{
		if([mRecentlyPlayedShuffleSongs count] > 0)
		{
			//Change the next radio song so that the user can move
			//one song forward in their playback history.
			self.nextShuffleSong = mPlayingSong;
			
			Song *previousSong = [mRecentlyPlayedShuffleSongs lastObject];
			[mRecentlyPlayedShuffleSongs removeLastObject];
			
			self.playingSong = previousSong;
		}
		else
		{
			self.currentTime = 0.0;
		}
		
		return;
	}
	
	NSUInteger indexOfSong = [mPlayQueue indexOfObject:mPlayingSong];
	if(indexOfSong == NSNotFound)
	{
		[self stop];
		return;
	}
    
	if(indexOfSong == 0)
	{
		self.currentTime = 0.0;
		return;
	}
	
	NSUInteger indexOfPreviousSong = indexOfSong - 1;
    if(self.mode == kAudioPlayerModeRepeatSong)
        indexOfPreviousSong = indexOfSong;
    
	self.playingSong = [mPlayQueue objectAtIndex:indexOfPreviousSong];
}

- (void)playNextSongInQueue
{
	if(mShuffleMode)
	{
		NSArray *allSongs = [Library sharedLibrary].songs;
		if(([allSongs count] == 0) || ([allSongs count] <= [mRecentlyPlayedShuffleSongs count]))
			return;
		
		//The next song is suppose to be calculated ahead of time,
		//we double-check this to prevent unpleasant errors.
		if(!self.nextShuffleSong)
		{
			NSLog(@"self.nextRadioSong was nil!");
			[self selectNextShuffleSong];
		}
		
		if(self.playingSong && ![mRecentlyPlayedShuffleSongs containsObject:self.playingSong])
			[mRecentlyPlayedShuffleSongs addObject:self.playingSong];
		
		self.playingSong = self.nextShuffleSong;
		
		if([mRecentlyPlayedShuffleSongs count] > [self numberOfRecentlyPlayedSongsToTrackForShuffleMode])
		{
			NSUInteger numberOfSongsToRemove = [mRecentlyPlayedShuffleSongs count] - ([self numberOfRecentlyPlayedSongsToTrackForShuffleMode] - 1);
			[mRecentlyPlayedShuffleSongs removeObjectsInRange:NSMakeRange(0, numberOfSongsToRemove)];
		}
		
		[self selectNextShuffleSong];
		
		return;
	}
	
	NSUInteger indexOfSong = [mPlayQueue indexOfObject:mPlayingSong];
	if(indexOfSong == NSNotFound)
	{
		[self stop];
		return;
	}
	
	NSUInteger indexOfNextSong = indexOfSong + 1;
    if(self.mode == kAudioPlayerModeRepeatSong)
    {
        indexOfNextSong = indexOfSong;
	}
    else if(indexOfNextSong >= [mPlayQueue count])
	{
        if(self.mode == kAudioPlayerModeNormal)
        {
            [self stop];
            
            return;
        }
        else
        {
            indexOfNextSong = 0;
        }
	}
	
	self.playingSong = [mPlayQueue objectAtIndex:indexOfNextSong];
}

- (void)pauseOrResume
{
	if(!self.isPlaying)
		return;
	
	[self willChangeValueForKey:@"isPaused"];
	
	if(mIsPaused)
	{
		mStartDate = [NSDate dateWithTimeIntervalSinceNow:-mCurrentTimeBeforePause];
		
		[mPlayer play];
		mIsPaused = NO;
	}
	else
	{
		mCurrentTimeBeforePause = self.currentTime;
		
		[mPlayer pause];
		mIsPaused = YES;
	}
	
	[self didChangeValueForKey:@"isPaused"];
}

- (void)stop
{
	[self willChangeValueForKey:@"playingSong"];
	
	[mPlayer pause];
	[self replaceCurrentPlayerItem:nil];
	
	[self willChangeValueForKey:@"isBuffering"];
	mIsBuffering = NO;
	[self didChangeValueForKey:@"isBuffering"];
	
	mCachedArtwork = nil;
	mPlayingSong = nil;
	mIsPaused = NO;
	
	[self didChangeValueForKey:@"playingSong"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AudioPlayerDoesNotHaveVideoNotification object:self];
	mLastTrackHadVideo = NO;
}

#pragma mark - Playback Control Actions

- (IBAction)playPause:(id)sender
{
	if(self.isPlaying)
	{
		[self pauseOrResume];
	}
	else if(mShuffleMode)
	{
		[self playNextSongInQueue];
	}
	else if([mPlayQueue count] > 0)
	{
		Song *song = RKCollectionGetFirstObject(mSelectedSongsInPlayQueue) ?: RKCollectionGetFirstObject(mPlayQueue);
		self.playingSong = song;
	}
	else
	{
		NSBeep();
	}
}

- (IBAction)previousTrack:(id)sender
{
	if(self.isPlaying)
	{
		NSDate *lastCall = [self associatedValueForKey:@"previousTrackLastCall"];
		
		if(self.currentTime <= 10.0 || (lastCall && ([[NSDate date] timeIntervalSinceDate:lastCall] < 3.0)))
			[self playPreviousSongInQueue];
		else
			self.currentTime = 0.0;
		
		[self setAssociatedValue:[NSDate date] forKey:@"previousTrackLastCall"];
	}
	else
	{
		NSBeep();
	}
}

- (IBAction)nextTrack:(id)sender
{
	if(self.isPlaying)
		[self playNextSongInQueue];
	else
		NSBeep();
}

#pragma mark -

- (IBAction)randomizePlayQueue:(id)sender
{
	if([mPlayQueue count] == 0)
		return;
	
	//From <http://www.cocoanetics.com/2009/04/shuffling-an-nsarray/>
	
	NSMutableArray *playQueue = [mPlayQueue mutableCopy];
	NSArray *playQueueHistory = nil;
	
	NSInteger numberOfRecentlyPlayedSongs = RKGetPersistentInteger(kNumberOfRecentlyPlayedSongsDefaultsKey);
	NSUInteger indexOfPlayingSong = [playQueue indexOfObject:mPlayingSong];
	if(indexOfPlayingSong != NSNotFound)
	{
		if(numberOfRecentlyPlayedSongs != -1)
			playQueueHistory = [playQueue subarrayWithRange:NSMakeRange(0, indexOfPlayingSong + 1)];
		else
			playQueueHistory = [NSArray arrayWithObject:self.playingSong];
	}
	
	[playQueue removeObjectsInArray:playQueueHistory];
	
	NSMutableArray *randomizedPlayQueue = [NSMutableArray array];
	for (Song *song in playQueue)
	{
		NSUInteger randomIndex = arc4random() % ([randomizedPlayQueue count] + 1);
		[randomizedPlayQueue insertObject:song atIndex:randomIndex];
	}
	
	//Ensure any relevant play queue history is kept at the top of the list
	[playQueueHistory enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Song *song, NSUInteger index, BOOL *stop) {
		[randomizedPlayQueue insertObject:song atIndex:0];
	}];
	
	self.playQueue = randomizedPlayQueue;
}

#pragma mark - User Interface Bindings

+ (NSSet *)keyPathsForValuesAffectingCanPreviousTrack
{
	return [NSSet setWithObjects:@"shuffleMode", @"isPlaying", @"playQueue.@count", nil];
}

- (BOOL)canPreviousTrack
{
	return (mShuffleMode || [mPlayQueue count] > 0) && self.isPlaying;
}

+ (NSSet *)keyPathsForValuesAffectingCanNextTrack
{
	return [NSSet setWithObjects:@"shuffleMode", @"isPlaying", @"playQueue.@count", nil];
}

- (BOOL)canNextTrack
{
	return (mShuffleMode || [mPlayQueue count] > 0) && self.isPlaying;
}

+ (NSSet *)keyPathsForValuesAffectingCanPlayPause
{
	return [NSSet setWithObjects:@"shuffleMode", @"playQueue.@count", nil];
}

- (BOOL)canPlayPause
{
	return mShuffleMode || ([mPlayQueue count] > 0);
}

+ (NSSet *)keyPathsForValuesAffectingCanRandomizePlayQueue
{
	return [NSSet setWithObjects:@"shuffleMode", @"playQueue.@count", nil];
}

- (BOOL)canRandomizePlayQueue
{
	return !mShuffleMode && ([mPlayQueue count] > 0);
}

@end
