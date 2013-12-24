//
//  AppDelegate.m
//  Pinna
//
//  Created by Peter MacWhinnie on 10/29/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "RKSandboxTools.h"

#import "AudioPlayer.h"
#import "ArtworkCache.h"

#import "MainWindow.h"
#import "MenuGenerator.h"
#import "PreferencesWindow.h"
#import "ScriptingController.h"

#import "MenuNotificationView.h"

#import "PlayerApplication.h"
#import "LastFMSession.h"
#import "LastFMDefines.h"

#import "ExfmSession.h"
#import "Library.h"
#import "SongQueryPromise.h"

#import "AccountManager.h"
#import "Account.h"
#import "ServiceDescriptor.h"

#import "Song.h"

static NSString *const kShowSongChangeNotificationsDefaultsKey = @"ShowSongChangeNotifications";
static NSString *const kHasShownDownloadPlayKeysAlertDefaultsKey = @"HasShownDownloadPlayKeysAlert";
static NSString *const kAlwaysShowSongChangeNotificationsWithoutGrowlDefaultsKey = @"AlwaysShowSongChangeNotificationsWithoutGrowl";

#pragma mark -

@implementation AppDelegate

- (id)init
{
	if((self = [super init]))
	{
		//Ensure the `Player` constant isn't nil.
		player = [AudioPlayer sharedAudioPlayer];
		
		mMainWindow = [MainWindow new];
		
        [self reauthorizeAccounts];
        
        
        [NSApp addImportantQueue:[ExfmSession sessionRequestQueue]];
        
        
		mPlayKeysBridge = [PlayKeysBridge playKeysBridge];
		mPlayKeysBridge.delegate = self;
		
		HotKeyDispatcher *hotKeyDispatcher = [HotKeyDispatcher sharedHotKeyDispatcher];
		hotKeyDispatcher.delegate = self;
		hotKeyDispatcher.playPauseCombo = KeyComboFromDictionary([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"HotKeys_playPause"]);
		hotKeyDispatcher.nextTrackCombo = KeyComboFromDictionary([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"HotKeys_nextTrack"]);
		hotKeyDispatcher.previousTrackCombo = KeyComboFromDictionary([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"HotKeys_previousTrack"]);
		
		//We disable the media keys option if the companion app isn't installed.
		if(!mPlayKeysBridge.isPlayKeysAppInstalled)
		{
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ListenToMediaKeys"];
		}
		
		if(RKProcessIsRunningInDebugger())
		{
			mPlayKeysBridge.enabled = NO;
		}
		else
		{
			[mPlayKeysBridge bind:@"enabled" 
						 toObject:[NSUserDefaults standardUserDefaults] 
					  withKeyPath:@"ListenToMediaKeys" 
						  options:nil];
			if(!mPlayKeysBridge.isPlayKeysAppRunning)
				[mPlayKeysBridge launchPlayKeysApp];
		}
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector(playKeysReady:) 
																name:@"com.roundabout.Pinna:playKeysReady" 
															  object:nil];
        
		[player addObserver:self forKeyPath:@"playingSong" options:0 context:NULL];
		[player addObserver:self forKeyPath:@"isPaused" options:0 context:NULL];
		
		mBackgroundStatusView = [MenuNotificationView new];
		[Player addObserver:self forKeyPath:@"artwork" options:0 context:NULL];
		
		if([NSSharingService class])
		{
			//We call this now to prevent initialization lag later.
			[NSSharingService sharingServicesForItems:@[@""]];
		}
        
        //We add an update pulse as well as ensuring we update the
        //cached songs when our internet connection is resumed.
        mUpdatePulse = [NSTimer scheduledTimerWithTimeInterval:(5.0 * RK_TIME_MINUTE)
                                                        target:self
                                                      selector:@selector(updatePulseFired:)
                                                      userInfo:nil
                                                       repeats:YES];
        RKConnectivityManager *internetConnection = [RKConnectivityManager defaultInternetConnectivityManager];
        [internetConnection registerStatusChangedBlock:^(RKConnectivityManager *sender) {
            if(internetConnection.isConnected) {
                [mUpdatePulse fire];
                [self reauthorizeAccounts];
            }
        }];
	}
	
	return self;
}

#pragma mark - Application Delegate

#pragma mark • Responding to Opens

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	[NSApp replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
	
	NSUInteger returnCode = 0;
	if(RKPersistentValueExists(@"SavedReturnCode_AppDelegate_openFilesPromptReturnCode"))
	{
		returnCode = RKGetPersistentInteger(@"SavedReturnCode_AppDelegate_openFilesPromptReturnCode");
	}
	else
	{
		NSString *heading = ([filenames count] > 1)? @"Would you like to play this file?" : @"Would you like to play these files?";
		NSString *informativeText = ([filenames count] > 1)? @"" : @"";
		
		NSAlert *openFilesPrompt = [NSAlert alertWithMessageText:heading
												   defaultButton:@"Play Now"
												 alternateButton:@"Cancel"
													 otherButton:@"Add to Queue"
									   informativeTextWithFormat:@"%@", informativeText];
		[openFilesPrompt setShowsSuppressionButton:YES];
		returnCode = [openFilesPrompt runModal];
		if([[openFilesPrompt suppressionButton] state] == NSOnState &&
		   returnCode != NSAlertAlternateReturn)
		{
			RKSetPersistentInteger(@"SavedReturnCode_AppDelegate_openFilesPromptReturnCode", returnCode);
		}
	}
	
	if(returnCode == NSAlertDefaultReturn)
	{
		NSArray *songs = RKCollectionMapToArray(filenames, ^Song *(NSString *path) {
			return [[Song alloc] initWithLocation:[NSURL fileURLWithPath:path]];
		});
		[player playSongsImmediately:songs];
	}
	else if(returnCode == NSAlertOtherReturn)
	{
		NSArray *songs = RKCollectionMapToArray(filenames, ^Song *(NSString *path) {
			return [[Song alloc] initWithLocation:[NSURL fileURLWithPath:path]];
		});
		[player addSongsToPlayQueue:songs];
	}
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	if([urlString hasPrefix:@"pinna-exfm:"])
	{
		NSString *urlWithoutProtocol = [[urlString substringFromIndex:[@"pinna-exfm:" length]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if([urlWithoutProtocol length] == 0)
			return;
		NSArray *exFMSongIdentifiers = [urlWithoutProtocol componentsSeparatedByString:@","];
		
		NSString *messageText = nil;
		NSString *informativeText = nil;
		if([exFMSongIdentifiers count] > 1)
		{
			messageText = @"Pinna Has Been Sent Songs from Another Application";
			informativeText = @"";
		}
		else
		{
			messageText = @"Pinna Has Been Sent a Song from Another Application";
			informativeText = @"";
		}
		
		NSInteger returnCode = [[NSAlert alertWithMessageText:messageText
												defaultButton:@"Play Now"
											  alternateButton:@"Cancel"
												  otherButton:@"Add to Queue"
									informativeTextWithFormat:@"%@", informativeText] runModal];
		if(returnCode != NSAlertAlternateReturn)
		{
			ExfmSession *exFMSession = [ExfmSession defaultSession];
			NSArray *songPromises = RKCollectionMapToArray(exFMSongIdentifiers, ^id(NSString *identifier) {
				if([identifier rangeOfString:@"$"].location != NSNotFound)
					return [[SongQueryPromise alloc] initWithIdentifier:identifier];
				
				return [exFMSession songWithID:identifier];
			});
			[[RKPromise when:songPromises] then:^(NSArray *possibilities) {
				__block BOOL thereWereErrors = NO;
                NSMutableString *songsNotFoundManifest = [NSMutableString string];
				NSArray *songs = RKCollectionMapToArray(possibilities, ^id(RKPossibility *maybeSongResult) {
					if(maybeSongResult.error)
					{
						thereWereErrors = YES;
                        
                        NSError *error = maybeSongResult.error;
                        [songsNotFoundManifest appendFormat:@"• %@ by %@",
                         error.userInfo[SongQueryPromiseSongNameErrorKey],
                         error.userInfo[SongQueryPromiseSongArtistErrorKey]];
                        
						return nil;
					}
					
					if([maybeSongResult.value isKindOfClass:[Song class]])
						return maybeSongResult.value;
					
					NSDictionary *songResult = maybeSongResult.value;
					return [[Song alloc] initWithTrackDictionary:[songResult objectForKey:@"song"] source:kSongSourceExfm];
				});
				
				if(returnCode == NSAlertDefaultReturn)
				{
					//Turn off shuffle mode.
					if(player.shuffleMode)
						[mMainWindow toggleShuffleMode:nil];
					
					[player playSongsImmediately:songs];
				}
				else
				{
					[player addSongsToPlayQueue:songs];
				}
				
				if(thereWereErrors)
				{
					[[NSAlert alertWithMessageText:@"The Following Songs Sent to Pinna Could Not Be Found"
									 defaultButton:nil
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:@"%@", songsNotFoundManifest] runModal];
				}
			} otherwise:^(NSError *error) {
                //Do nothing
            }];
			
			[mMainWindow showWindow:nil];
		}
	}
	else
	{
		NSLog(@"Unhandled URL «%@»", urlString);
	}
}

#pragma mark - • App Lifecycle

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[NSApp setServicesProvider:self];
    
	//Honor command up and down for controlling volume.
	[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *event) {
		if([event keyCode] == 126/*up arrow*/ && RK_FLAG_IS_SET([event modifierFlags], NSCommandKeyMask))
		{
			[self increaseVolume:nil];
			return nil;
		}
		else if([event keyCode] == 125/*down arrow*/ && RK_FLAG_IS_SET([event modifierFlags], NSCommandKeyMask))
		{
			[self decreaseVolume:nil];
			return nil;
		}
		
		return event;
	}];
	
	[mMainWindow showWindow:nil];
	
	if(!RKProcessIsRunningInDebugger())
	{
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.roundabout.PlayKeys:appLaunched"
																	   object:[[NSBundle mainBundle] bundleIdentifier]];
	}
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
													   andSelector:@selector(handleURLEvent:withReplyEvent:)
													 forEventClass:kInternetEventClass
														andEventID:kAEGetURL];
	
	//Enable JSTalk support.
	[NSApp broadcastToJSTalkWithRootObject:[[ScriptingController alloc] initWithMainWindow:mMainWindow]];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	if(!RKProcessIsRunningInDebugger())
	{
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.roundabout.PlayKeys:appTerminated" 
																	   object:[[NSBundle mainBundle] bundleIdentifier]];
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	[mMainWindow showWindow:nil];
	return YES;
}

#pragma mark -

- (void)waitForImportantQueuesToFinish
{
	[NSApp waitForImportantQueuesToFinish];
	
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSArray *importantQueues = [NSApp importantQueues];
	for (NSOperationQueue *importantQueue in importantQueues)
	{
		if([importantQueue operationCount] > 0)
		{
			[oBusyWindow center];
			[oBusyWindow makeKeyAndOrderFront:nil];
			
			[NSThread detachNewThreadSelector:@selector(waitForImportantQueuesToFinish) 
									 toTarget:self 
								   withObject:nil];
			
			return NSTerminateLater;
		}
	}
	
	return NSTerminateNow;
}

#pragma mark - • Update Pulse

- (void)updatePulseFired:(NSTimer *)sender
{
    [[ExfmSession defaultSession] updateCachedSongs];
}

#pragma mark - • Other

- (void)playKeysReady:(NSNotification *)notification
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.roundabout.Pinna:playKeysReady" object:nil];
	
	RKSetPersistentBool(@"ListenToMediaKeys", YES);
}

#pragma mark - Services

- (void)searchForQueryOnExFM:(NSPasteboard *)pasteboard userData:(NSDictionary *)userData error:(NSString **)error
{
	NSString *query = [pasteboard stringForType:(NSString *)(kUTTypeUTF8PlainText)];
	[mMainWindow searchInExploreForQuery:query];
}

#pragma mark - Notifications

- (BOOL)shouldPostNotifications
{
	return (RKGetPersistentBool(kShowSongChangeNotificationsDefaultsKey) && ![NSApp mainWindow]);
}

#pragma mark - Account Manager

- (void)reauthorizeAccounts
{
    if([RKConnectivityManager defaultInternetConnectivityManager].isConnected)
    {
        for (Account *account in [AccountManager sharedAccountManager].accounts)
        {
            RKPromise *reloginPromise = [account.descriptor.service reloginWithAccount:account];
            if(!reloginPromise)
                continue;
            
            [reloginPromise then:^(id <Service> service) {
                
            } otherwise:^(NSError *error) {
                NSLog(@"Could not reauthorize account %@. %@", account, error);
            }];
        }
    }
}

#pragma mark - Scrobbling

- (BOOL)hasSongBeenPlayedEnoughForScrobble:(Song *)song
{
    if(!song)
        return NO;
    
    //This is obviously a terrible lie, but there is currently no reliable
    //way to determine if an exfm-sourced song has been played enough.
    if(song.songSource == kSongSourceExfm && song.duration == 0.0)
        return YES;
    
    return (song.duration > 30.0 && (-[song.lastPlayed timeIntervalSinceNow] >= song.duration / 2.0));
}

- (void)sendNowPlayingInfo:(NSTimer *)timer
{
	if(mPrivateListeningEnabled ||
       !RKGetPersistentBool(@"ScrobblePlayedSongsAndUpdateNowPlaying") ||
       ![RKConnectivityManager defaultInternetConnectivityManager].isConnected)
    {
		return;
	}
    
	if(player.playingSong)
	{
		Song *playingSong = player.playingSong;
		mLastSong = playingSong;
        
        for (Account *account in [AccountManager sharedAccountManager].accounts)
        {
            id <Service> service = account.descriptor.service;
            if(!service)
                continue;
            
            RKPromise *updatePromise = [service updateNowPlayingWithSong:playingSong duration:playingSong.duration];
			[updatePromise then:^(id data) {
                NSLog(@"updated (%@) on %@!", playingSong, account.serviceIdentifier);
            } otherwise:^(NSError *error) {
                NSLog(@"Could not update playing song on %@. Error %@", account.serviceIdentifier, error);
            }];
        }
	}
	
	mNowPlayingUpdateDelayTimer = nil;
}

- (void)updateNowPlayingStatus
{
    if(mPrivateListeningEnabled)
        return;
    
	if([self hasSongBeenPlayedEnoughForScrobble:mLastSong])
	{
        if(!RKGetPersistentBool(@"ScrobblePlayedSongsAndUpdateNowPlaying") ||
           ![RKConnectivityManager defaultInternetConnectivityManager].isConnected)
        {
            return;
        }
        
        Song *lastSong = mLastSong;
        for (Account *service in [AccountManager sharedAccountManager].accounts)
        {
            id <Service> scrobbler = service.descriptor.service;
            if(!scrobbler)
                continue;
            
            RKPromise *scrobblePromise = [scrobbler scrobbleSong:lastSong duration:mLastSong.duration];
			[scrobblePromise then:^(id data) {
                NSLog(@"scrobbled (%@) on %@!", lastSong, service.serviceIdentifier);
            } otherwise:^(NSError *error) {
                NSLog(@"Could not scrobble song on %@. Error %@", service.serviceIdentifier, error);
            }];
        }
        
        mLastSong = nil;
	}
	
	//We schedule now playing updates on a timer in the event
	//the user is skipping forward rapidly in their library.
	if(player.playingSong)
	{
		if(mNowPlayingUpdateDelayTimer)
		{
			[mNowPlayingUpdateDelayTimer invalidate];
			mNowPlayingUpdateDelayTimer = nil;
		}
		
		mNowPlayingUpdateDelayTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 
																	   target:self 
																	 selector:@selector(sendNowPlayingInfo:) 
																	 userInfo:nil 
																	  repeats:NO];
	}
}

#pragma mark - Observations

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if((object == player) && [keyPath isEqualToString:@"playingSong"])
	{
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:ScriptingControllerPlayingSongDidChangeNotification object:@"com.roundabout.pinna"];
		
		[self updateNowPlayingStatus];
		if(player.isPlaying || player.isPaused)
		{
			Song *playingSong = player.playingSong;
			[oPlaybackStatusItem setTitle:[NSString stringWithFormat:@"“%@” by %@", playingSong.name, playingSong.artist]];
			
			if([self shouldPostNotifications])
			{
				mBackgroundStatusView.isPaused = player.isPaused;
				mBackgroundStatusView.title = player.playingSong.name;
				[mBackgroundStatusView show];
			}
		}
		else
		{
			[oPlaybackStatusItem setTitle:@"Nothing Playing"];
			
			if([self shouldPostNotifications])
			{
				mBackgroundStatusView.isPaused = YES;
				mBackgroundStatusView.title = nil;
				[mBackgroundStatusView show];
			}
		}
	}
	else if((object == player) && [keyPath isEqualToString:@"artwork"])
	{
		NSImage *artwork = (player.artwork ?: [NSImage imageNamed:@"NoArtwork"]);
		mBackgroundStatusView.image = artwork;
	}
	else if((object == player) && [keyPath isEqualToString:@"isPaused"])
	{
		if(player.isPaused)
		{
			if([self shouldPostNotifications])
			{
				mBackgroundStatusView.isPaused = YES;
				mBackgroundStatusView.title = nil;
				[mBackgroundStatusView show];
			}
		}
		else
		{
			if([self shouldPostNotifications] && player.playingSong)
			{
				mBackgroundStatusView.isPaused = NO;
				mBackgroundStatusView.title = player.playingSong.name;
				[mBackgroundStatusView show];
			}
		}
	}
}

#pragma mark - Interface Hooks

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	if([item action] == @selector(previousTrack:))
	{
		return Player.canPreviousTrack;
	}
	else if([item action] == @selector(nextTrack:))
	{
		return Player.canNextTrack;
	}
	else if([item action] == @selector(playPause:))
	{
		return Player.canPlayPause;
	}
	else if([item action] == @selector(randomizePlayQueue:))
	{
		return Player.canRandomizePlayQueue;
	}
	else if([item action] == @selector(changeQueueHistoryAmount:))
	{
		NSMenuItem *menuItem = (NSMenuItem *)item;
		NSUInteger numberOfRecentlyPlayedSongs = RKGetPersistentInteger(@"AudioPlayer_numberOfRecentlyPlayedSongs");
		if([menuItem tag] == numberOfRecentlyPlayedSongs)
			[menuItem setState:NSOnState];
		else
			[menuItem setState:NSOffState];
	}
	else if([item action] == @selector(togglePrivateListening:))
	{
		return mScrobbler.isAuthorized;
	}
	else if([item action] == @selector(showMainWindow:))
	{
		return (![[mMainWindow window] isVisible] && ![[mMainWindow shuffleWindow] isVisible]);
	}
	
	return YES;
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingPlayPauseMenuItemTitle
{
	return [NSSet setWithObjects:@"player.playingSong", @"player.isPlaying", @"player.isPaused", nil];
}

- (NSString *)playPauseMenuItemTitle
{
	if(player.isPlaying && !player.isPaused)
		return @"Pause";
	
	return @"Play";
}

+ (NSSet *)keyPathsForValuesAffectingToggleShuffleMenuItemTitle
{
	return [NSSet setWithObjects:@"player.shuffleMode", nil];
}

- (NSString *)toggleShuffleMenuItemTitle
{
	if(Player.shuffleMode)
		return @"Turn Off Library Shuffle";
	
	return @"Turn On Library Shuffle";
}

#pragma mark - Showing Subcontrollers

- (IBAction)showMainWindow:(id)sender
{
	[mMainWindow showWindow:sender];
}

- (IBAction)showPreferencesWindow:(id)sender
{
	PreferencesWindow *preferencesWindow = [self preferencesWindow];
	
	if([[preferencesWindow window] isVisible] && [[preferencesWindow window] isMainWindow])
		[preferencesWindow close];
	else
		[preferencesWindow showWindow:sender];
}

#pragma mark - Playback Control Actions

- (IBAction)playPause:(id)sender
{
	[player playPause:sender];
}

- (IBAction)previousTrack:(id)sender
{
	[player previousTrack:sender];
}

- (IBAction)nextTrack:(id)sender
{
	[player nextTrack:sender];
}

#pragma mark -

- (IBAction)randomizePlayQueue:(id)sender
{
	[player randomizePlayQueue:sender];
}

- (IBAction)toggleShuffleMode:(id)sender
{
	[mMainWindow toggleShuffleMode:sender];
}

- (IBAction)takeNewPlaybackModeFrom:(id)sender
{
    player.mode = [sender tag];
}

#pragma mark -

- (IBAction)increaseVolume:(id)sender
{
	CGFloat newVolume = player.volume + 0.05;
	if(newVolume > 1.0)
		newVolume = 1.0;
	
	player.volume = newVolume;
}

- (IBAction)decreaseVolume:(id)sender
{
	CGFloat newVolume = player.volume - 0.05;
	if(newVolume < 0.0)
		newVolume = 1.0;
	
	player.volume = newVolume;
}

#pragma mark - Other

- (IBAction)togglePrivateListening:(id)sender
{
	if(!mPrivateListeningEnabled && !RK_FLAG_IS_SET([NSEvent modifierFlags], NSAlternateKeyMask))
	{
		NSAlert *confirmationAlert = [NSAlert new];
		[confirmationAlert setMessageText:@"Are You Sure You Want to Turn on Private Listening?"];
		[confirmationAlert setInformativeText:@"When private listening is turned on, now playing updates and played songs are not submitted to Last.fm."];
		[confirmationAlert addButtonWithTitle:@"OK"];
		[confirmationAlert addButtonWithTitle:@"Cancel"];
		
		if([confirmationAlert runModal] == NSAlertSecondButtonReturn)
		{
			[self willChangeValueForKey:@"mPrivateListeningEnabled"];
			mPrivateListeningEnabled = YES; //Will be inverted by the menu item that sent this action.
			[self didChangeValueForKey:@"mPrivateListeningEnabled"];
		}
	}
}

- (IBAction)deleteArtworkCaches:(id)sender
{
	NSInteger returnCode = [[NSAlert alertWithMessageText:@"Are You Sure You Want to Empty the Artwork Cache" 
											defaultButton:@"Empty Artwork Cache" 
										  alternateButton:@"Cancel" 
											  otherButton:nil 
								informativeTextWithFormat:@"Emptying the artwork cache will cause all the artwork to disappear from the album browser until Pinna's next internal library update cycle.\n\nYou should only empty the artwork cache if you are experiencing issues with artwork displaying properly."] runModal];
	if(returnCode == NSOKButton)
		[[ArtworkCache sharedArtworkCache] deleteCachedArtwork];
}

- (IBAction)changeQueueHistoryAmount:(id)sender
{
	RKSetPersistentInteger(@"AudioPlayer_numberOfRecentlyPlayedSongs", [sender tag]);
}

- (IBAction)refresh:(id)sender
{
	NSDate *timeSinceLastRefresh = [self associatedValueForKey:@"refresh-timeSinceLastRefresh"];
	if(!timeSinceLastRefresh ||
	   (-[timeSinceLastRefresh timeIntervalSinceNow]) >= 5.0)
	{
		[[ExfmSession defaultSession] updateCachedSongs];
		[self setAssociatedValue:[NSDate date] forKey:@"refresh-timeSinceLastRefresh"];
	}
}

#pragma mark - Properties

@synthesize mainWindow = mMainWindow;

- (PreferencesWindow *)preferencesWindow
{
	if(!mPreferencesWindow)
		mPreferencesWindow = [PreferencesWindow new];
	
	return mPreferencesWindow;
}

#pragma mark - Hot Keys

- (void)playKeysBridge:(PlayKeysBridge *)bridge mediaKeyWasPressed:(MediaKeyCode)key
{
}

- (void)playKeysBridge:(PlayKeysBridge *)bridge mediaKeyIsBeingHeld:(MediaKeyCode)key
{
	switch (key)
	{
		case kMediaKeyCodeNext:
			[self setAssociatedValue:[NSNumber numberWithBool:YES] forKey:@"mediaKeyWasHeld"];
			player.currentTime += 2.0;
			break;
			
		case kMediaKeyCodePrevious:
			[self setAssociatedValue:[NSNumber numberWithBool:YES] forKey:@"mediaKeyWasHeld"];
			player.currentTime -= 2.0;
			break;
			
		default:
			break;
	}
}

- (void)playKeysBridge:(PlayKeysBridge *)bridge mediaKeyWasReleased:(MediaKeyCode)key
{
	if([self associatedValueForKey:@"mediaKeyWasHeld"])
	{
		[self setAssociatedValue:nil forKey:@"mediaKeyWasHeld"];
		return;
	}
	
	switch (key)
	{
		case kMediaKeyCodePlayPause:
			[self playPause:nil];
			break;
			
		case kMediaKeyCodeNext:
			[self nextTrack:nil];
			break;
			
		case kMediaKeyCodePrevious:
			[self previousTrack:nil];
			break;
			
		default:
			break;
	}
}

#pragma mark -

- (void)hotKeyDispatcherDetectedPlayPause:(HotKeyDispatcher *)sender
{
	[self playPause:nil];
}

- (void)hotKeyDispatcherDetectedNextTrack:(HotKeyDispatcher *)sender
{
	[self nextTrack:nil];
}

- (void)hotKeyDispatcherDetectedPreviousTrack:(HotKeyDispatcher *)sender
{
	[self previousTrack:nil];
}

@end
