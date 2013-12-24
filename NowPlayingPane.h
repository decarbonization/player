//
//  NowPlaying.h
//  Pinna
//
//  Created by Peter MacWhinnie on 1/5/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "AudioPlayer.h"
#import "RKChromeView.h"

@class AudioPlayer;
@class MainWindow;
@class ScrubbingBarView, ArtworkImageView;
@class LyricsViewController;

@protocol NowPlayingPaneDelegate;

///The view controller responsible for the now playing pain in Player's Main Window.
@interface NowPlayingPane : NSViewController <NSWindowDelegate, NSApplicationDelegate, NSAnimationDelegate, AudioPlayerPulseObserver, RKChromeViewDelegate>
{
	/** Bindings **/
	
	AudioPlayer *player;
	
	
	/** State **/
	
	///The parent main window of the now playing pane.
	MainWindow *mMainWindow;
	
	///The lyrics view controller.
	LyricsViewController *mLyricsController;
	
	///The lyrics popover.
	NSPopover *mLyricsPopover;
	
	
	/** Outlets **/
	
	///The view at the top of the now playing area that displays the shadow.
	IBOutlet NSImageView *oShadowImageView;
	
	///The view used to display album artwork.
	IBOutlet RKChromeView *oArtworkImageView;
	
	///The view that contains the information area.
	IBOutlet RKChromeView *oInformationAreaView;
	
	///The button used to toggle the artwork.
	IBOutlet NSButton *oArtworkToggleButton;
	
	///The song title label.
	IBOutlet NSTextField *oSongTitleLabel;
	
	///The song information label.
	IBOutlet NSTextField *oSongInfoLabel;
	
	///The scrubbing bar to control playback-location.
	IBOutlet ScrubbingBarView *oScrubbingBar;
	
	
	/** Properties **/
	
	///Backing for `delegate`.
	id <NowPlayingPaneDelegate> mDelegate;
	
	///Backing for `canToggleArtwork`.
	BOOL mCanToggleArtwork;
}

///Initialize the now playing pane with a specified parent main window.
- (id)initWithMainWindow:(MainWindow *)mainWindow;

#pragma mark - Modes

///Whether or not the now playing pane can toggle its artwork.
@property (nonatomic) BOOL canToggleArtwork;

#pragma mark -

///Returns the height of the information area.
- (CGFloat)heightOfInformationArea;

#pragma mark -

///Whether or not the artwork is visible.
@property (nonatomic, readonly) BOOL isArtworkVisible;

///Resets the positioning of the receiver's artwork view.
- (void)resetArtwork;

///Show the receiver's artwork view.
- (void)showArtwork;

///Hides the receiver's artwork view.
- (void)hideArtwork;

///Toggle the visibility of the artwork.
- (IBAction)toggleArtwork:(id)sender;

#pragma mark -

///The delegate of the now playing pane.
@property (nonatomic) id <NowPlayingPaneDelegate> delegate;

#pragma mark - Lyrics

///Returns whether or not the lyrics are visible.
- (BOOL)isLyricsVisible;

///Shows the lyrics popover.
- (void)showLyrics;

///Hides the lyrics popover.
- (void)hideLyrics;

#pragma mark - Actions

///Shows the lyrics popover.
- (IBAction)bringUpLyrics:(NSButton *)sender;

@end

#pragma mark -

///The delegate of NowPlayingPane
@protocol NowPlayingPaneDelegate <NSObject>

///Sent when the now playing pane has shown its artwork.
- (void)nowPlayingPaneDidShowArtwork:(NowPlayingPane *)pane;

///Sent when the now playing pane will hide its artwork.
- (void)nowPlayingPaneWillHideArtwork:(NowPlayingPane *)pane;

///Sent when the now playing pane has hidden its artwork.
- (void)nowPlayingPaneDidHideArtwork:(NowPlayingPane *)pane;

@end
