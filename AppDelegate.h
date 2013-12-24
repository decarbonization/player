//
//  AppDelegate.h
//  Pinna
//
//  Created by Peter MacWhinnie on 10/29/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlayKeysBridge.h"
#import "HotKeyDispatcher.h"

@class MainWindow, PreferencesWindow, EffectsWindow;
@class LastFMSession, Song, AudioPlayer, MenuNotificationView;

///The class responsible for tying all of Player's disparate controllers together.
@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserInterfaceValidations, PlayKeysBridgeDelegate, HotKeyDispatcherDelegate>
{
	/** Outlets **/
	
	///The window to display when Player is busy in the background when the user asks to quit.
	IBOutlet NSWindow *oBusyWindow;
	
	///The menu item in the dock menu used to display playback status.
	IBOutlet NSMenuItem *oPlaybackStatusItem;
	
	/** Subcontrollers **/
	
	///The main window.
	MainWindow *mMainWindow;
	
	///The preferences window.
	PreferencesWindow *mPreferencesWindow;
	
	///The background status view used to display notifications.
	MenuNotificationView *mBackgroundStatusView;
	
	
	/** Internal **/
	
	///The player of the delegate.
	AudioPlayer *player;
	
	///Whether or not private listening is enabled.
	BOOL mPrivateListeningEnabled;
	
	///The scrobbler that belongs to Player.
	LastFMSession *mScrobbler;
	
	Song *mLastSong;
	
	///The timer used to make sure we don't flood Last.fm with now playing updates.
	NSTimer *mNowPlayingUpdateDelayTimer;
	
	///The media key watcher.
	PlayKeysBridge *mPlayKeysBridge;
    
    ///The update pulse timer.
    NSTimer *mUpdatePulse;
}

#pragma mark Interface Hooks

///The title for play pause menu items.
- (NSString *)playPauseMenuItemTitle;

///The title for toggle shulfle menu items.
- (NSString *)toggleShuffleMenuItemTitle;

#pragma mark - Showing Subcontrollers

///Shows the main window.
- (IBAction)showMainWindow:(id)sender;

///Shows the preferences window.
- (IBAction)showPreferencesWindow:(id)sender;

#pragma mark - Playback Control Actions

///Toggle the playback state of the receiver.
- (IBAction)playPause:(id)sender;

///Move to the previous track in the receiver's player's play queue.
- (IBAction)previousTrack:(id)sender;

///Move to the next track in the receiver's player's play queue.
- (IBAction)nextTrack:(id)sender;

#pragma mark -

///Randomizes the play queue.
- (IBAction)randomizePlayQueue:(id)sender;

///Toggle shuffle mode on the play queue.
- (IBAction)toggleShuffleMode:(id)sender;

///Sets the shared audio player's mode to be that of the sender's tag.
- (IBAction)takeNewPlaybackModeFrom:(id)sender;

#pragma mark -

///Increases the application volume.
- (IBAction)increaseVolume:(id)sender;

///Decreases the application volume.
- (IBAction)decreaseVolume:(id)sender;

#pragma mark - Other

///Toggle the state of private listening.
- (IBAction)togglePrivateListening:(id)sender;

///Causes the artwork cache of Player to be destroyed.
- (IBAction)deleteArtworkCaches:(id)sender;

///Change the amount of history to keep in the play queue.
- (IBAction)changeQueueHistoryAmount:(id)sender;

///Refresh everything possible to refresh.
- (IBAction)refresh:(id)sender;

#pragma mark - Properties

@property (readonly, nonatomic) PreferencesWindow *preferencesWindow;

@property (readonly, nonatomic) MainWindow *mainWindow;

@end
