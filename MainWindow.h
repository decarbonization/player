//
//  MainWindow.h
//  Pinna
//
//  Created by Peter MacWhinnie on 10/29/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKBorderlessWindow.h"
#import "RKChromeView.h"

@class AudioPlayer, Library, NowPlayingPane, ExFMTrendingSourceController, ErrorBannerView;
@class QueueTableView, WebView, RKBrowserView, RKBrowserLevel;
@class RKTitleBarButtonsView, HeaderLabelView, BackgroundArtworkDisplayView, ScrubbingBarView;

///The browser being displayed in a main window object.
enum MainWindowBrowserMode {
	kMainWindowBrowserModePlaylist = 0,
	kMainWindowBrowserModeSong = 1,
	kMainWindowBrowserModeArtist = 2,
	kMainWindowBrowserModeAlbum = 3,
	kMainWindowBrowserModeExplore = 4,
};
typedef NSInteger MainWindowBrowserMode;

///The MainWindow class is responsible for creating and
///maintaining the main window of the Player application.
@interface MainWindow : NSWindowController <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate, RKBorderlessWindowDelegate, NSAnimationDelegate, NSUserInterfaceValidations>
{
	/** Bindings **/
	
	AudioPlayer *player;
	
	BOOL mouseInsideTitleBarWithOptionKeyHeld;
	
	
	/** State **/
	
	///The browser currently selected.
	MainWindowBrowserMode mBrowserMode;
	
	///The browser states.
	RKBrowserLevel *mPlaylistsBrowserLevel;
	RKBrowserLevel *mSongsBrowserLevel;
	RKBrowserLevel *mArtistsBrowserLevel;
	RKBrowserLevel *mAlbumsBrowserLevel;
	RKBrowserLevel *mExploreBrowserLevel;
	
	///The string used by the search field.
	NSString *mSearchString;
	
	///The current library error presentation view.
	ErrorBannerView *mLibraryErrorBannerView;
	
	///The current playback error presentation view.
	ErrorBannerView *mPlaybackErrorBannerView;
	
	
	/** Outlets **/
	
	///The title bar buttons of the window.
	IBOutlet RKTitleBarButtonsView *oTitleBarButtons;
	
	///The top chrome view.
	IBOutlet RKChromeView *oTopChromeView;
	
	///The left pane of the `oMainWindowSplitView`.
	NSView *mSplitViewLeftPane;
	
	///The right pane of the `oMainWindowSplitView`.
	NSView *mSplitViewRightPane;
	
	///The split view.
	IBOutlet NSSplitView *oMainWindowSplitView;
	
	
	///The search field used for the browser.
	IBOutlet NSSearchField *oBrowserSearchField;
	
	///The button used to navigate backwards in the browser.
	///*Used only for maintaining a proper width for the library pane's header.
	IBOutlet NSButton *oLibraryBackButton;
	
	///The ehader label used to display the title of the library browser.
	IBOutlet HeaderLabelView *oLibraryHeaderLabel;
	
	///The box that displays whatever the current browser is.
	IBOutlet RKBrowserView *oLibraryBrowser;
	
	///The matrix used to display the mode chooser for the library.
	IBOutlet NSMatrix *oLibraryModeChooser;
	
	///The controller used to display the ex.fm trending menu.
	ExFMTrendingSourceController *mExFMTrendingSourceController;
	
	
	///The table view that displays the main window's player's play queue.
	IBOutlet QueueTableView *oPlayQueueTableView;
	
	///The array controller that populates the main window's `playQueueTableView`.
	IBOutlet NSArrayController *oPlayQueueArrayController;
	
	///The header of the browser pane.
	IBOutlet HeaderLabelView *oPlayQueueHeaderLabel;
	
	///The browser view that hosts the now playing area.
	IBOutlet NSView *oPlayQueueContainerView;
	
	///The play queue action button.
	IBOutlet NSButton *oPlayQueueClearButton;
	
	
	///The shuffle mode window.
	IBOutlet RKBorderlessWindow *oShuffleModeWindow;
    
    ///The shuffle mode header.
    IBOutlet HeaderLabelView *oShuffleHeaderView;
	
	///The box used to contain shuffle mode's now playing pane.
	IBOutlet NSBox *oShuffleModeNowPlayingContainer;
	
	///The now playing pane used by shuffle mode.
	NowPlayingPane *mShuffleModeNowPlayingPane;
	
	
	///The video window.
	IBOutlet NSWindow *oVideoWindow;
	
	///The view used to host the video.
	IBOutlet RKChromeView *oVideoHostView;
	
	
	///The now playing pane of the main window.
	NowPlayingPane *mNowPlayingPane;
	
	///The window used to display the background artwork display
	NSWindow *mBackgroundArtworkWindow;
	
	///The view used to display the background artwork.
	BackgroundArtworkDisplayView *mBackgroundArtworkDisplayView;
	
	///The timer used to delay the closing of art mode.
	NSTimer *mBackgroundArtworkWindowCloseDelay;
	
	///Whether or not the now playing pane was expanded before a drag operation on the queue.
	BOOL mNowPlayingWasExpandedBeforeQueueDragOperation;
}

#pragma mark Interface Hooks

#pragma mark • Bindings

///The image that the play-pause button should display.
@property (nonatomic, readonly) NSImage *playPauseButtonImage;

///The image that the play-pause button should display when clicked.
@property (nonatomic, readonly) NSImage *playPauseButtonPressedImage;

#pragma mark -

///The tooltip of the queue header to use.
@property (nonatomic, readonly) NSString *queueHeaderToolTip;

#pragma mark - • Search Field

///The string currently being searched for.
@property (nonatomic, copy) NSString *searchString;

///Search for a specified query in the explore pane.
- (void)searchInExploreForQuery:(NSString *)query;

#pragma mark - • Browser

///The browser mode of the main window.
@property (nonatomic) MainWindowBrowserMode browserMode;

#pragma mark -

///Sent when the current browser selection changes.
- (IBAction)currentBrowserSelectionDidChange:(id)sender;

#pragma mark - Playback Control Actions

///Toggle the playback state of the receiver.
- (IBAction)playPause:(id)sender;

///Move to the previous track in the receiver's player's play queue.
- (IBAction)previousTrack:(id)sender;

///Move to the next track in the receiver's player's play queue.
- (IBAction)nextTrack:(id)sender;

#pragma mark -

///Shuffles the play queue.
- (IBAction)randomizePlayQueue:(id)sender;

#pragma mark -

///The shuffle window of the main window.
@property (nonatomic, readonly) NSWindow *shuffleWindow;

///Activates shuffle mode.
- (IBAction)activateShuffleMode:(id)sender;

///Deactivates shuffle mode.
- (IBAction)deactivateShuffleMode:(id)sender;

///Toggles shuffle mode.
- (IBAction)toggleShuffleMode:(id)sender;

#pragma mark - Other Actions

///Causes the receiver to clear the play queue.
- (IBAction)clearPlayQueue:(id)sender;

///Show the lyrics window.
- (IBAction)showLyrics:(id)sender;

///Shows the video window.
- (IBAction)showVideo:(id)sender;

#pragma mark - Switching Browsers

- (IBAction)showPlaylistsPane:(id)sender;
- (IBAction)showSongsPane:(id)sender;
- (IBAction)showArtistsPane:(id)sender;
- (IBAction)showAlbumsPane:(id)sender;
- (IBAction)showExplorePane:(id)sender;

#pragma mark - Background Artwork

///Close the background artwork if it is open.
- (void)closeBackgroundArtwork;

///Open the background artwork if the situation is appropriate.
- (void)showBackgroundArtwork;

#pragma mark - Error Handling

///Present a specified library error.
- (void)presentLibraryError:(NSError *)error;

///Present a specified playback error.
- (void)presentPlaybackError:(NSError *)error;

@end
