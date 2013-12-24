//
//  MainWindow.m
//  Pinna
//
//  Created by Peter MacWhinnie on 10/29/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "MainWindow.h"

//Views
#import "QueueTableView.h"
#import "RKBrowserIconTextFieldCell.h"
#import "HeaderLabelView.h"
#import "BackgroundArtworkDisplayView.h"
#import "ErrorBannerView.h"

#import "RKKeyDispatcher.h"
#import "RKBorderlessWindow.h"
#import "RKTitleBarButtonsView.h"

//Animations
#import "WindowTransition.h"
#import "RKAnimator.h"

//Subordinate Controllers
#import "MenuGenerator.h"
#import "NowPlayingPane.h"
#import "ExFMTrendingSourceController.h"

//Library & Playback
#import "AudioPlayer.h"
#import "Library.h"
#import "Artist.h"
#import "ExfmSession.h"
#import "FileEnumerator.h"

//Browsers
#import "RKBrowserView.h"
#import "RKBrowserLevel.h"

#import "SongsBrowserLevel.h"
#import "PlaylistsBrowserLevel.h"
#import "ArtistsBrowserLevel.h"
#import "AlbumsBrowserLevel.h"
#import "ExploreBrowserLevel.h"


static NSGradient *_PlayingSongBackgroundGradient = nil;

static NSTimeInterval kTimeUntilArtModeIsClosed = 0.25;

static NSString *const kBrowserModeDefaultsKey = @"MainWindow_browserMode";
static NSString *const kShouldShowBackgroundModeDefaultsKey = @"MainWindow_shouldShowBackgroundMode";
static NSString *const kArtModeSquareSizeDefaultsKey = @"MainWindow_artModeSquareSize";
static NSString *const kAutomaticallyShowVideoWindowDefaultsKey = @"MainWindow_automaticallyShowVideoWindow";

enum ArtModeWindowLevels {
	kArtModeWindowLevelDesktop = (-1),
	kArtModeWindowLevelNormal = 0,
	kArtModeWindowLevelFloating = 1,
};
static NSString *const kArtModeWindowLevelDefaultsKey = @"MainWindow_artModeWindowLevel";

static NSString *const kScrubbingBarUseTimeRemainingDisplayStyleDefaultsKey = @"MainWindow_scrubbingBarUseTimeRemainingDisplayStyle";

#pragma mark -

@interface MainWindow () <NowPlayingPaneDelegate, NSSharingServiceDelegate>

@end

@implementation MainWindow

#pragma mark - Initialization

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)initialize
{
	_PlayingSongBackgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.33 green:0.33 blue:0.56 alpha:0.5]
																   endingColor:[NSColor colorWithCalibratedRed:0.43 green:0.44 blue:0.74 alpha:0.35]];
	
	[super initialize];
}

- (id)init
{
	if((self = [super initWithWindowNibName:@"MainWindow"]))
	{
		player = [AudioPlayer sharedAudioPlayer];
		
		[player addObserver:self forKeyPath:@"playingSong" options:NSKeyValueObservingOptionOld context:NULL];
		[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"AudioPlayer_numberOfRecentlyPlayedSongs" options:0 context:NULL];
		
		mNowPlayingPane = [[NowPlayingPane alloc] initWithMainWindow:self];
		mNowPlayingPane.delegate = self;
	}
	
	return self;
}

- (void)windowDidLoad
{
	[[self window] setFrameAutosaveName:@"Main Window"];
	
	//We (MainWindow) are responsible for maintaining the AudioPlayer's selected songs property.
	[player bind:@"selectedSongsInPlayQueue" 
		toObject:oPlayQueueArrayController 
	 withKeyPath:NSSelectedObjectsBinding 
		 options:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(deactivateShuffleMode:) 
												 name:AudioPlayerShuffleModeFailedNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(audioPlayerErrorDidOccur:)
												 name:AudioPlayerErrorDidOccurNotification
											   object:player];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(libraryErrorDidOccur:)
												 name:LibraryErrorDidOccurNotification
											   object:nil];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(libraryDidUpdate:)
												 name:LibraryDidUpdateNotification
											   object:[Library sharedLibrary]];
	
	
	[oLibraryBrowser addObserver:self forKeyPath:@"canGoBack" options:0 context:NULL];
	
	
	//Stylize the play queue table view.
	[oPlayQueueTableView setIntercellSpacing:NSZeroSize];
	[oPlayQueueTableView registerForDraggedTypes:@[kSongUTI, (__bridge NSString *)kUTTypeFileURL]];
	[oPlayQueueTableView setTarget:self];
	[oPlayQueueTableView setDoubleAction:@selector(tableViewWasDoubleClicked:)];
	[oPlayQueueTableView sizeToFit];
	
	
	//Setup the appropriate key listeners
	RKKeyDispatcher *playQueueTableViewKeyListener = oPlayQueueTableView.keyListener;
	[playQueueTableViewKeyListener setHandlerForKeyCode:/*delete*/51 block:^(NSUInteger modifierFlags) {
		[oPlayQueueArrayController remove:nil];
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			if(![player.playQueue containsObject:player.playingSong])
				[player stop];
		}];
		
		return YES;
	}];
	
	[playQueueTableViewKeyListener setHandlerForKeyCode:/*enter*/36 block:^(NSUInteger modifierFlags) {
		[Player playSongsImmediately:[oPlayQueueArrayController selectedObjects]];
		
		return YES;
	}];
	
	
	RKKeyDispatcher *windowKeyListener = [(RKBorderlessWindow *)[self window] keyListener];
	[windowKeyListener setHandlerForKeyCode:/*space*/49 block:^(NSUInteger modifierFlags) {
		[self playPause:nil];
		return YES;
	}];
	
	oShuffleModeWindow.keyListener = windowKeyListener;
	
	
	//Setup the background artwork view
	mBackgroundArtworkWindow = [[NSWindow alloc] initWithContentRect:NSZeroRect 
														   styleMask:NSBorderlessWindowMask 
															 backing:NSBackingStoreBuffered 
															   defer:NO];
	[mBackgroundArtworkWindow setOneShot:NO];
	[mBackgroundArtworkWindow setReleasedWhenClosed:NO];
	[mBackgroundArtworkWindow setHasShadow:YES];
	[mBackgroundArtworkWindow setTitle:@"Pinna"];
	[mBackgroundArtworkWindow setContentView:[[NSView alloc] initWithFrame:NSZeroRect]];
	[mBackgroundArtworkWindow setMovableByWindowBackground:YES];
	
	NSInteger artModeWindowLevel = [[NSUserDefaults standardUserDefaults] integerForKey:kArtModeWindowLevelDefaultsKey];
	switch (artModeWindowLevel)
	{
		case kArtModeWindowLevelFloating:
			[mBackgroundArtworkWindow setLevel:NSStatusWindowLevel];
			break;
			
		case kArtModeWindowLevelDesktop:
			[mBackgroundArtworkWindow setLevel:CGWindowLevelForKey(kCGDesktopWindowLevelKey)];
			break;
			
		default:
			break;
	}
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kArtModeWindowLevelDefaultsKey options:0 context:NULL];
	
	mBackgroundArtworkDisplayView = [[BackgroundArtworkDisplayView alloc] initWithFrame:NSZeroRect];
	[mBackgroundArtworkDisplayView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[mBackgroundArtworkDisplayView bind:@"image" 
							   toObject:Player 
							withKeyPath:@"artwork" 
								options:@{NSNullPlaceholderBindingOption: [NSImage imageNamed:@"NoArtwork"]}];
	
	[[mBackgroundArtworkWindow contentView] addSubview:mBackgroundArtworkDisplayView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(applicationDidBecomeActive:) 
												 name:NSApplicationDidBecomeActiveNotification 
											   object:NSApp];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(applicationDidResignActive:) 
												 name:NSApplicationDidResignActiveNotification 
											   object:NSApp];
	
	//Setup Shuffle mode
	mShuffleModeNowPlayingPane = [[NowPlayingPane alloc] initWithMainWindow:self];
	mShuffleModeNowPlayingPane.canToggleArtwork = NO;
	[oShuffleModeNowPlayingContainer setContentView:[mShuffleModeNowPlayingPane view]];
	
	
	//Setup video mode
	[oVideoHostView setWantsLayer:YES];
	[oVideoHostView setLayer:player.playerVideoLayer];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(audioPlayerHasVideo:) 
												 name:AudioPlayerHasVideoNotification 
											   object:player];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(audioPlayerDoesNotHaveVideo:) 
												 name:AudioPlayerDoesNotHaveVideoNotification 
											   object:player];
	
	
	//Setup the library header
	[self hideBackButton];
	
	oLibraryHeaderLabel.leftMargin = NSMaxX([oTitleBarButtons frame]) + 5.0;
	
	[oLibraryHeaderLabel bind:@"string" 
					 toObject:self 
				  withKeyPath:@"oLibraryBrowser.browserLevel.title" 
					  options:nil];
	
	[oLibraryHeaderLabel bind:@"showBusyIndicator" 
					 toObject:[RKActivityManager sharedActivityManager]
				  withKeyPath:@"isActive" 
					  options:nil];
    [oShuffleHeaderView bind:@"showBusyIndicator"
                    toObject:[RKActivityManager sharedActivityManager]
                 withKeyPath:@"isActive"
                     options:nil];
	
	//Setup the library browser mode chooser.
	MainWindowBrowserMode browserMode = [[NSUserDefaults standardUserDefaults] integerForKey:kBrowserModeDefaultsKey];
	[oLibraryModeChooser selectCellWithTag:browserMode];
	self.browserMode = browserMode;
}

#pragma mark - Gunk

///The amount of padding on the interior of the search bar.
///
///This const should be updated if the main window is updated.
static CGFloat const kSearchBarInteriorPadding = 7.0;

- (BOOL)isBackButtonVisible
{
	return (NSMinX([oLibraryBackButton frame]) >= 0.0);
}

- (void)hideBackButton
{
	if(![self isBackButtonVisible])
		return;
	
	NSRect searchBarFrame = [[oBrowserSearchField superview] frame];
	
	NSRect newBackButtonFrame = [oLibraryBackButton frame];
	newBackButtonFrame.origin.x = -NSWidth(newBackButtonFrame);
	
	NSRect newSearchFieldFrame = [oBrowserSearchField frame];
	newSearchFieldFrame.size.width = NSWidth(searchBarFrame) - (kSearchBarInteriorPadding * 2.0);
	newSearchFieldFrame.origin.x = kSearchBarInteriorPadding;
	
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction setFrame:newBackButtonFrame forTarget:oLibraryBackButton];
		[transaction setFrame:newSearchFieldFrame forTarget:oBrowserSearchField];
    }];
}

- (void)showBackButton
{
	if([self isBackButtonVisible])
		return;
	
	NSRect searchBarFrame = [[oBrowserSearchField superview] frame];
	
	NSRect newBackButtonFrame = [oLibraryBackButton frame];
	newBackButtonFrame.origin.x = 0.0;
	
	NSRect newSearchFieldFrame = [oBrowserSearchField frame];
	newSearchFieldFrame.size.width = NSWidth(searchBarFrame) - (kSearchBarInteriorPadding * 2.0) - NSMaxX(newBackButtonFrame);
	newSearchFieldFrame.origin.x = kSearchBarInteriorPadding + NSMaxX(newBackButtonFrame);
	
	[[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction setFrame:newBackButtonFrame forTarget:oLibraryBackButton];
		[transaction setFrame:newSearchFieldFrame forTarget:oBrowserSearchField];
    }];
}

#pragma mark -

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	if([item action] == @selector(showPlaylistsPane:))
	{
		[(NSMenuItem *)item setState:(self.browserMode == kMainWindowBrowserModePlaylist)];
	}
	else if([item action] == @selector(showSongsPane:))
	{
		[(NSMenuItem *)item setState:(self.browserMode == kMainWindowBrowserModeSong)];
	}
	else if([item action] == @selector(showArtistsPane:))
	{
		[(NSMenuItem *)item setState:(self.browserMode == kMainWindowBrowserModeArtist)];
	}
	else if([item action] == @selector(showAlbumsPane:))
	{
		[(NSMenuItem *)item setState:(self.browserMode == kMainWindowBrowserModeAlbum)];
	}
	else if([item action] == @selector(showExplorePane:))
	{
		[(NSMenuItem *)item setState:(self.browserMode == kMainWindowBrowserModeExplore)];
	}
	else if([item action] == @selector(showLyrics:))
	{
		return player.isPlaying;
	}
	else if([item action] == @selector(showVideo:))
	{
		return player.playerHasVideo;
	}
	else if([item action] == @selector(toggleLoveForSelection:))
	{
		if(![ExfmSession defaultSession].isAuthorized)
			return NO;
		
		if([[self window] firstResponder] == oPlayQueueTableView)
		{
			return [[oPlayQueueTableView selectedRowIndexes] count] > 0;
		}
		else
		{
			return [oLibraryBrowser.browserLevel.selectedItems count] > 0;
		}
	}
    
	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if((object == [NSUserDefaults standardUserDefaults]) && [keyPath isEqualToString:@"AudioPlayer_numberOfRecentlyPlayedSongs"])
	{
		[oPlayQueueTableView setNeedsDisplay];
	}
	else if((object == [NSUserDefaults standardUserDefaults]) && [keyPath isEqualToString:kArtModeWindowLevelDefaultsKey])
	{
		NSInteger artModeWindowLevel = [[NSUserDefaults standardUserDefaults] integerForKey:kArtModeWindowLevelDefaultsKey];
		switch (artModeWindowLevel)
		{
			case kArtModeWindowLevelFloating:
				[mBackgroundArtworkWindow setLevel:NSStatusWindowLevel];
				break;
				
			case kArtModeWindowLevelDesktop:
				[mBackgroundArtworkWindow setLevel:CGWindowLevelForKey(kCGDesktopWindowLevelKey)];
				break;
				
			case kArtModeWindowLevelNormal:
			default:
				[mBackgroundArtworkWindow setLevel:NSNormalWindowLevel];
				break;
		}
	}
	else if((object == player) && [keyPath isEqualToString:@"playingSong"])
	{
		[oPlayQueueTableView setNeedsDisplay];
		
		if(player.isPlaying)
		{
			if(!player.shuffleMode)
				[self showBackgroundArtwork];
			
			[self raiseNowPlayingIntoView];
		}
		else
		{
			[self closeBackgroundArtwork];
			[self hideNowPlayingFromView];
		}
	}
}

- (void)libraryDidUpdate:(NSNotification *)notification
{
	NSInteger hoveredUponRow = oPlayQueueTableView.hoveredUponRow;
	if(hoveredUponRow != -1)
		[oPlayQueueTableView setNeedsDisplayInRect:[oPlayQueueTableView rectOfRow:hoveredUponRow]];
}

#pragma mark -

- (void)audioPlayerErrorDidOccur:(NSNotification *)notification
{
	NSError *error = [[notification userInfo] objectForKey:@"error"];
	[self presentPlaybackError:error];
}

- (void)libraryErrorDidOccur:(NSNotification *)notification
{
	NSError *error = [[notification userInfo] objectForKey:@"error"];
	[self presentLibraryError:error];
}

#pragma mark -

- (void)showWindow:(id)sender
{
	if(player.shuffleMode)
		[oShuffleModeWindow makeKeyAndOrderFront:sender];
	else
		[super showWindow:sender];
}

#pragma mark -

- (void)audioPlayerHasVideo:(NSNotification *)notification
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:kAutomaticallyShowVideoWindowDefaultsKey])
		[oVideoWindow makeKeyAndOrderFront:nil];
}

- (void)audioPlayerDoesNotHaveVideo:(NSNotification *)notification
{
	[oVideoWindow close];
}

#pragma mark - • Bindings

+ (NSSet *)keyPathsForValuesAffectingPlayPauseButtonImage
{
	return [NSSet setWithObjects:@"player.isPaused", @"player.isPlaying", nil];
}

- (NSImage *)playPauseButtonImage
{
	if(player.isPlaying && !player.isPaused)
		return [NSImage imageNamed:@"Pause_Button"];
	
	return [NSImage imageNamed:@"Play_Button"];
}

+ (NSSet *)keyPathsForValuesAffectingPlayPauseButtonPressedImage
{
	return [NSSet setWithObjects:@"player.isPaused", @"player.isPlaying", nil];
}

- (NSImage *)playPauseButtonPressedImage
{
	if(player.isPlaying && !player.isPaused)
		return [NSImage imageNamed:@"Pause_ButtonPressed"];
	
	return [NSImage imageNamed:@"Play_ButtonPressed"];
}

#pragma mark -

+ (NSSet *)keyPathsForValuesAffectingQueueHeaderToolTip
{
	return [NSSet setWithObjects:@"player.shuffleMode", @"player.durationOfQueue", nil];
}

- (NSString *)queueHeaderToolTip
{
	return [NSString stringWithFormat:@"%ld Songs", [player.playQueue count]];
}

#pragma mark - • Now Playing

- (void)raiseNowPlayingIntoView
{
	if([[mNowPlayingPane view] superview])
		return;
	
	NSView *nowPlayingPaneView = [mNowPlayingPane view];
	NSRect initialNowPlayingPaneViewFrame = NSMakeRect(0.0, 
													   -[mNowPlayingPane heightOfInformationArea], 
													   NSWidth([oPlayQueueContainerView frame]), 
													   [mNowPlayingPane heightOfInformationArea]);
	[nowPlayingPaneView setFrame:initialNowPlayingPaneViewFrame];
	[nowPlayingPaneView setAutoresizingMask:NSViewWidthSizable | NSViewMinXMargin];
	[oPlayQueueContainerView addSubview:nowPlayingPaneView];
	
	[mNowPlayingPane resetArtwork];
	
	NSRect targetNowPlayingPaneViewFrame = initialNowPlayingPaneViewFrame;
	targetNowPlayingPaneViewFrame.origin.y = 0.0;
	
	NSRect targetQueueTableViewFrame = [[oPlayQueueTableView enclosingScrollView] frame];
	targetQueueTableViewFrame.size.height = (NSHeight([oPlayQueueContainerView frame]) - NSHeight(targetNowPlayingPaneViewFrame)) + 3.0;
	targetQueueTableViewFrame.origin.y = (NSHeight(targetNowPlayingPaneViewFrame) - 3.0);
	
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction setFrame:targetNowPlayingPaneViewFrame forTarget:nowPlayingPaneView];
		[transaction setFrame:targetQueueTableViewFrame forTarget:[oPlayQueueTableView enclosingScrollView]];
    }];
}

- (void)hideNowPlayingFromView
{
	if(![[mNowPlayingPane view] superview])
		return;
	
	NSView *nowPlayingPaneView = [mNowPlayingPane view];
	NSRect targetNowPlayingPaneViewFrame = [nowPlayingPaneView frame];
	targetNowPlayingPaneViewFrame.origin.y = -NSHeight(targetNowPlayingPaneViewFrame);
	
	NSRect targetQueueTableViewFrame = [[oPlayQueueTableView enclosingScrollView] frame];
	targetQueueTableViewFrame.size.height = NSHeight([oPlayQueueContainerView frame]);
	targetQueueTableViewFrame.origin.y = 0.0;
	
	[[oPlayQueueTableView enclosingScrollView] setHidden:NO];
	
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction setFrame:targetNowPlayingPaneViewFrame forTarget:nowPlayingPaneView];
		[transaction setFrame:targetQueueTableViewFrame forTarget:[oPlayQueueTableView enclosingScrollView]];
    } completionHandler:^(BOOL didFinish) {
        [oPlayQueueClearButton setHidden:NO];
		[nowPlayingPaneView removeFromSuperview];
    }];
}

- (void)nowPlayingPaneDidShowArtwork:(NowPlayingPane *)pane
{
	[oPlayQueueClearButton setHidden:YES];
	
	[[mNowPlayingPane view] setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[[oPlayQueueTableView enclosingScrollView] setHidden:YES];
}

- (void)nowPlayingPaneWillHideArtwork:(NowPlayingPane *)pane
{
	[[oPlayQueueTableView enclosingScrollView] setHidden:NO];
}

- (void)nowPlayingPaneDidHideArtwork:(NowPlayingPane *)pane
{
	[[mNowPlayingPane view] setAutoresizingMask:NSViewWidthSizable | NSViewMinXMargin];
	
	[oPlayQueueClearButton setHidden:NO];
}

#pragma mark - • Search Field

@synthesize searchString = mSearchString;

- (void)searchInExploreForQuery:(NSString *)query
{
	if(player.shuffleMode)
		[self toggleShuffleMode:nil];
	
	if(!query) query = @"";
	
	if(self.browserMode != kMainWindowBrowserModeExplore)
	{
		self.browserMode = kMainWindowBrowserModeExplore;
		[oLibraryModeChooser selectCellWithTag:kMainWindowBrowserModeExplore];
	}
	self.searchString = query;
}

#pragma mark - • Browser

- (void)setBrowserMode:(MainWindowBrowserMode)tag
{
	mBrowserMode = tag;
	[[NSUserDefaults standardUserDefaults] setInteger:mBrowserMode 
											   forKey:kBrowserModeDefaultsKey];
	
	RKBrowserLevel *newLevel = nil;
	switch (mBrowserMode)
	{
		case kMainWindowBrowserModePlaylist:
		{
			if(!mPlaylistsBrowserLevel)
				mPlaylistsBrowserLevel = [PlaylistsBrowserLevel new];
			newLevel = mPlaylistsBrowserLevel;
			
			break;
		}
			
		case kMainWindowBrowserModeSong:
		{
			if(!mSongsBrowserLevel)
				mSongsBrowserLevel = [SongsBrowserLevel new];
			newLevel = mSongsBrowserLevel;
			
			break;
		}
			
		case kMainWindowBrowserModeArtist:
		{
			if(!mArtistsBrowserLevel)
				mArtistsBrowserLevel = [ArtistsBrowserLevel new];
			newLevel = mArtistsBrowserLevel;
			
			break;
		}
			
		case kMainWindowBrowserModeAlbum:
		{
			if(!mAlbumsBrowserLevel)
				mAlbumsBrowserLevel = [AlbumsBrowserLevel new];
			
			newLevel = mAlbumsBrowserLevel;
			
			break;
		}
			
		case kMainWindowBrowserModeExplore:
		{
			if(!mExploreBrowserLevel)
				mExploreBrowserLevel = [ExploreBrowserLevel new];
			
			newLevel = mExploreBrowserLevel;
			
			break;
		}
			
		default:
			NSAssert(0, @"Unrecognized browser.");
	}
	
	newLevel.searchString = nil;
	oLibraryBrowser.browserLevel = newLevel;
	
	if(mBrowserMode == kMainWindowBrowserModeExplore)
	{
		[[oBrowserSearchField cell] setSendsWholeSearchString:YES];
		
		oLibraryHeaderLabel.action = @selector(showTrendingSelectionMenu:);
		oLibraryHeaderLabel.target = self;
		
		[oLibraryHeaderLabel bind:@"clickable" 
						 toObject:newLevel 
					  withKeyPath:@"isSearching" 
						  options:@{NSValueTransformerNameBindingOption: @"NSNegateBoolean"}];
	}
	else
	{
		[[oBrowserSearchField cell] setSendsWholeSearchString:NO];
		oLibraryHeaderLabel.action = nil;
		oLibraryHeaderLabel.target = nil;
		
		[oLibraryHeaderLabel unbind:@"clickable"];
	}
}

- (MainWindowBrowserMode)browserMode
{
	return mBrowserMode;
}

#pragma mark -

- (IBAction)currentBrowserSelectionDidChange:(id)sender
{
	MainWindowBrowserMode browserMode = [sender selectedTag];
	if(browserMode == mBrowserMode)
	{
		[oLibraryBrowser goToRoot:sender];
	}
	else
	{
		self.browserMode = browserMode;
	}
}

#pragma mark - Other Actions

- (IBAction)clearPlayQueue:(id)sender
{
	NSInteger returnCode = [[NSAlert alertWithMessageText:@"Are you sure you want to clear the contents of the queue?"
											defaultButton:@"Clear Queue"
										  alternateButton:@"Cancel"
											  otherButton:nil
								informativeTextWithFormat:@"This operation cannot be undone"] runModal];
	if(returnCode == NSOKButton)
	{
		NSMutableArray *playQueue = [player mutableArrayValueForKey:@"playQueue"];
		[playQueue removeAllObjects];
		if(player.playingSong)
			[playQueue addObject:player.playingSong];
	}
}

- (IBAction)showLyrics:(id)sender
{
	if(!player.isPlaying)
		return;
	
	if(player.shuffleMode)
	{
		if(mShuffleModeNowPlayingPane.isLyricsVisible)
			[mShuffleModeNowPlayingPane hideLyrics];
		else
			[mShuffleModeNowPlayingPane showLyrics];
	}
	else
	{
		if(mNowPlayingPane.isLyricsVisible)
			[mNowPlayingPane hideLyrics];
		else
			[mNowPlayingPane showLyrics];
	}
}

- (IBAction)showVideo:(id)sender
{
	if(!player.playerHasVideo)
	{
		NSBeep();
		return;
	}
	
	if([oVideoWindow isVisible])
		[oVideoWindow close];
	else
		[oVideoWindow makeKeyAndOrderFront:sender];
}

#pragma mark - Switching Browsers

- (IBAction)showPlaylistsPane:(id)sender
{
	[oLibraryModeChooser selectCellWithTag:kMainWindowBrowserModePlaylist];
	[oLibraryModeChooser sendAction];
}

- (IBAction)showSongsPane:(id)sender
{
	[oLibraryModeChooser selectCellWithTag:kMainWindowBrowserModeSong];
	[oLibraryModeChooser sendAction];
}

- (IBAction)showArtistsPane:(id)sender
{
	[oLibraryModeChooser selectCellWithTag:kMainWindowBrowserModeArtist];
	[oLibraryModeChooser sendAction];
}

- (IBAction)showAlbumsPane:(id)sender
{
	[oLibraryModeChooser selectCellWithTag:kMainWindowBrowserModeAlbum];
	[oLibraryModeChooser sendAction];
}

- (IBAction)showExplorePane:(id)sender
{
	[oLibraryModeChooser selectCellWithTag:kMainWindowBrowserModeExplore];
	[oLibraryModeChooser sendAction];
}

#pragma mark - Discovery

- (IBAction)showTrendingSelectionMenu:(id)sender
{
	if(!mExFMTrendingSourceController)
		mExFMTrendingSourceController = [ExFMTrendingSourceController new];
	
	[mExFMTrendingSourceController showBelowView:oLibraryHeaderLabel];
}

#pragma mark - Playback Control Actions

- (IBAction)playPause:(id)sender
{
	[Player playPause:sender];
}

- (IBAction)previousTrack:(id)sender
{
	[Player previousTrack:sender];
}

- (IBAction)nextTrack:(id)sender
{
	[Player nextTrack:sender];
}

#pragma mark -

- (IBAction)randomizePlayQueue:(id)sender
{
	[Player randomizePlayQueue:sender];
}

#pragma mark -

@synthesize shuffleWindow = oShuffleModeWindow;

- (IBAction)activateShuffleMode:(id)sender
{
	if(player.shuffleMode)
		return;
	
	if(RK_FLAG_IS_SET([NSEvent modifierFlags], NSShiftKeyMask))
	{
		[self randomizePlayQueue:sender];
	}
	else
	{
		NSRect mainWindowFrame = [[self window] frame];
		NSRect shuffleWindowFrame = [oShuffleModeWindow frame];
		shuffleWindowFrame.origin.x = round(NSMidX(mainWindowFrame) - NSWidth(shuffleWindowFrame) / 2.0);
		shuffleWindowFrame.origin.y = round(NSMidY(mainWindowFrame) - NSHeight(shuffleWindowFrame) / 2.0);
		[oShuffleModeWindow setFrame:shuffleWindowFrame display:NO];
		
		player.shuffleMode = YES;
		
		if(!player.isPlaying)
			[player playPause:sender];
		
		if(player.shuffleMode && [mBackgroundArtworkWindow isVisible])
			return;
		
		if([NSApp isHidden])
		{
			[oShuffleModeWindow orderWindow:NSWindowBelow relativeTo:[[self window] windowNumber]];
			[[self window] close];
		}
		else
		{
			WindowTransition *transition = [[WindowTransition alloc] initWithSourceWindow:[self window] 
																			 targetWindow:oShuffleModeWindow];
			[transition transition:nil];
		}
	}
}

- (IBAction)deactivateShuffleMode:(id)sender
{
	player.shuffleMode = NO;
	
	if(RK_FLAG_IS_SET([NSEvent modifierFlags], NSAlternateKeyMask) && !player.isPaused)
	{
		[player addSongsToPlayQueue:@[player.playingSong]];
	}
	else
	{
		[player stop];
	}
	
	NSRect shuffleWindowFrame = [oShuffleModeWindow frame];
	NSRect mainWindowFrame = [[self window] frame];
	mainWindowFrame.origin.x = round(NSMidX(shuffleWindowFrame) - NSWidth(mainWindowFrame) / 2.0);
	mainWindowFrame.origin.y = round(NSMidY(shuffleWindowFrame) - NSHeight(mainWindowFrame) / 2.0);
	[[self window] setFrame:mainWindowFrame display:NO];
	
	if(player.isPlaying && [mBackgroundArtworkWindow isVisible])
		return;
	
	if([NSApp isHidden])
	{
		[[self window] orderWindow:NSWindowBelow relativeTo:[oShuffleModeWindow windowNumber]];
		[oShuffleModeWindow close];
	}
	else
	{
		WindowTransition *transition = [[WindowTransition alloc] initWithSourceWindow:oShuffleModeWindow 
																		 targetWindow:[self window]];
		[transition transition:nil];
	}
}

- (IBAction)toggleShuffleMode:(id)sender
{
	if(player.shuffleMode)
	{
		[self deactivateShuffleMode:sender];
	}
	else
	{
		[self activateShuffleMode:sender];
	}
}

#pragma mark - Background Artwork

- (NSWindow *)topMostWindow
{
	NSArray *orderedWindows = [NSApp orderedWindows];
	if([orderedWindows count] > 0)
		return [orderedWindows objectAtIndex:0];
	
	return nil;
}

#pragma mark -

- (NSSize)backgroundArtworkSize
{
	double artModeSquareSize = round([[NSUserDefaults standardUserDefaults] doubleForKey:kArtModeSquareSizeDefaultsKey]);
	return NSMakeSize(artModeSquareSize, artModeSquareSize);
}

///The different zones the main window can be positioned at on the user's screen.
typedef enum {
	
	kWindowZoneTopLeft,
	kWindowZoneTopRight,
	kWindowZoneTopCenter,
	
	kWindowZoneBottomLeft,
	kWindowZoneBottomRight,
	kWindowZoneBottomCenter,
	
	kWindowZoneCenterCenter,
	kWindowZoneCenterLeft,
	kWindowZoneCenterRight,
	
} WindowZone;

///Returns the main window's position on the user's screen.
- (WindowZone)zoneForWindow:(NSWindow *)window
{
	NSRect mainWindowFrame = [window frame];
	NSRect screenArea = [[window screen] visibleFrame];
	
	CGFloat thirdOfHeight = NSHeight(screenArea) / 3.0;
	CGFloat thirdOfWidth = NSWidth(screenArea) / 3.0;
	
	//These values must be calculated with secondary screens in mind.
	CGFloat minY = (NSMinY(mainWindowFrame) - NSMinY(screenArea));
	CGFloat midY = minY + (NSHeight(mainWindowFrame) / 2.0);
	
	CGFloat minX = (NSMinX(mainWindowFrame) - NSMinX(screenArea));
	CGFloat midX = minX + (NSWidth(mainWindowFrame) / 2.0);
	
	//Bottom third of the screen
	if(midY <= thirdOfHeight)
	{
		if(midX <= thirdOfWidth)
		{
			return kWindowZoneBottomLeft;
		}
		else if(midX <= thirdOfWidth * 2.0)
		{
			return kWindowZoneBottomCenter;
		}
		
		return kWindowZoneBottomRight;
	}
	
	//Middle third of the screen
	if(midY <= thirdOfHeight * 2.0)
	{
		if(midX <= thirdOfWidth)
		{
			return kWindowZoneCenterLeft;
		}
		else if(midX <= thirdOfWidth * 2.0)
		{
			return kWindowZoneCenterCenter;
		}
		
		return kWindowZoneCenterRight;
	}
	
	//Top third of the screen
	if(midX <= thirdOfWidth)
	{
		return kWindowZoneTopLeft;
	}
	else if(midX <= thirdOfWidth * 2.0)
	{
		return kWindowZoneTopCenter;
	}
	
	return kWindowZoneTopRight;
}

///Returns the appropriate target frame for a transition between the normal and art modes.
- (NSRect)targetTransitionFrameFromWindow:(NSWindow *)window targetSize:(NSSize)size
{
	WindowZone windowZone = [self zoneForWindow:window];
	NSRect targetWindowFrame = [window frame];
	
	switch (windowZone)
	{
		case kWindowZoneTopLeft:
			return NSMakeRect(NSMinX(targetWindowFrame), 
							  NSMaxY(targetWindowFrame) - size.height, 
							  size.width, 
							  size.height);
			
		case kWindowZoneTopRight:
			return NSMakeRect(NSMaxX(targetWindowFrame) - size.width, 
							  NSMaxY(targetWindowFrame) - size.height, 
							  size.width, 
							  size.height);
			
		case kWindowZoneTopCenter:
			return NSMakeRect(NSMidX(targetWindowFrame) - size.width / 2.0, 
							  NSMaxY(targetWindowFrame) - size.height, 
							  size.width, 
							  size.height);
			
			/* --- */
			
		case kWindowZoneBottomLeft:
			return NSMakeRect(NSMinX(targetWindowFrame), 
							  NSMinY(targetWindowFrame), 
							  size.width, 
							  size.height);
			
		case kWindowZoneBottomRight:
			return NSMakeRect(NSMaxX(targetWindowFrame) - size.width, 
							  NSMinY(targetWindowFrame), 
							  size.width, 
							  size.height);
			
		case kWindowZoneBottomCenter:
			return NSMakeRect(NSMidX(targetWindowFrame) - size.width / 2.0, 
							  NSMinY(targetWindowFrame), 
							  size.width, 
							  size.height);
			
			/* --- */
			
		case kWindowZoneCenterCenter:
			return NSMakeRect(NSMidX(targetWindowFrame) - size.width / 2.0, 
							  NSMidY(targetWindowFrame) - size.height / 2.0, 
							  size.width, 
							  size.height);
			
		case kWindowZoneCenterLeft:
			return NSMakeRect(NSMinX(targetWindowFrame), 
							  NSMidY(targetWindowFrame) - size.height / 2.0, 
							  size.width, 
							  size.height);
			
		case kWindowZoneCenterRight:
			return NSMakeRect(NSMaxX(targetWindowFrame) - size.width, 
							  NSMidY(targetWindowFrame) - size.height / 2.0, 
							  size.width, 
							  size.height);
			
			/* --- */
			
		default:
			NSAssert(0, @"Unknown window zone %d", windowZone);
			break;
	}
	
	return NSZeroRect;
}

#pragma mark -

- (void)closeBackgroundArtwork
{
	//If we don't wait for the next tick here, there's a chance this transition will
	//be mangled by us being activated by the 'desktop' during a spaces change.
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		if([mBackgroundArtworkWindow isVisible])
		{
			NSWindow *targetWindow = player.shuffleMode? oShuffleModeWindow : [self window];
			NSRect targetFrameForMainWindow = [self targetTransitionFrameFromWindow:mBackgroundArtworkWindow targetSize:[targetWindow frame].size];
			[targetWindow setFrame:targetFrameForMainWindow display:YES];
			[targetWindow setLevel:NSNormalWindowLevel];
			
			WindowTransition *transition = [[WindowTransition alloc] initWithSourceWindow:mBackgroundArtworkWindow 
																			 targetWindow:targetWindow];
			
			[transition transition:nil];
		}
	}];
}

- (void)showBackgroundArtwork
{
	if(![[NSUserDefaults standardUserDefaults] boolForKey:kShouldShowBackgroundModeDefaultsKey])
		return;
	
	if(![NSApp isHidden] && ![NSApp isActive] && player.isPlaying && 
	   ([[self topMostWindow] isEqualTo:[self window]] ||
		[[self topMostWindow] isEqualTo:oShuffleModeWindow]))
	{
		NSWindow *sourceWindow = player.shuffleMode? oShuffleModeWindow : [self window];
		NSRect targetFrameForArtwork = [self targetTransitionFrameFromWindow:sourceWindow targetSize:[self backgroundArtworkSize]];
		[mBackgroundArtworkWindow setFrame:targetFrameForArtwork display:YES];
		[sourceWindow setLevel:[mBackgroundArtworkWindow level]];
		
		WindowTransition *transition = [[WindowTransition alloc] initWithSourceWindow:sourceWindow 
																		 targetWindow:mBackgroundArtworkWindow];
		
		[transition transition:nil];
	}
}

#pragma mark -

- (void)closeBackgroundArtworkForTimer:(NSTimer *)timer
{
	if(mBackgroundArtworkDisplayView.isMouseInView)
	{
		mBackgroundArtworkWindowCloseDelay = [NSTimer scheduledTimerWithTimeInterval:([timer timeInterval] * 2.0) 
																			  target:self 
																			selector:@selector(closeBackgroundArtworkForTimer:) 
																			userInfo:nil 
																			 repeats:NO];
	}
	else
	{
		[self closeBackgroundArtwork];
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	mBackgroundArtworkWindowCloseDelay = [NSTimer scheduledTimerWithTimeInterval:kTimeUntilArtModeIsClosed 
																		  target:self 
																		selector:@selector(closeBackgroundArtworkForTimer:) 
																		userInfo:nil 
																		 repeats:NO];
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
	[mBackgroundArtworkWindowCloseDelay invalidate];
	mBackgroundArtworkWindowCloseDelay = nil;
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:kShouldShowBackgroundModeDefaultsKey])
	{
		[self showBackgroundArtwork];
	}
}

#pragma mark - Error Handling

- (void)presentLibraryError:(NSError *)error
{
	if(mLibraryErrorBannerView)
	{
		[mLibraryErrorBannerView close];
		mLibraryErrorBannerView = nil;
	}
	
    mLibraryErrorBannerView = [ErrorBannerView new];
    mLibraryErrorBannerView.title = [error localizedDescription] ?: @"";
    
    if(player.shuffleMode)
        [mPlaybackErrorBannerView showInView:oShuffleModeNowPlayingContainer];
    else
        [mLibraryErrorBannerView showInView:oLibraryBrowser];
}

- (void)presentPlaybackError:(NSError *)error
{
	//The keys of this table correspond to the relevant help document on the Pinna site.
	NSDictionary *helpURLs = @{
        @(kAudioPlayerCannotPlayProtectedFileErrorCode): [NSURL URLWithString:@"http://pinnaplayer.com/help/protectedfiles.html"],
        @(kAudioPlayerPlaybackFailedErrorCode): [NSURL URLWithString:@"http://pinnaplayer.com/help/failedplayback.html"],
        @(kAudioPlayerPlaybackStartFailedErrorCode): [NSURL URLWithString:@"http://pinnaplayer.com/help/failedplayback.html"],
        @(kAudioPlayerShuffleFailedErrorCode): [NSURL URLWithString:@"http://pinnaplayer.com/help/shufflefailed.html"],
    };
	
	
	if(mPlaybackErrorBannerView)
	{
		[mPlaybackErrorBannerView close];
		mPlaybackErrorBannerView = nil;
	}
	
    mPlaybackErrorBannerView = [ErrorBannerView new];
    mPlaybackErrorBannerView.title = [error localizedDescription] ?: @"";
    
    mPlaybackErrorBannerView.buttonTitle = @"Learn More";
    mPlaybackErrorBannerView.buttonAction = ^{
        NSURL *helpURL = [helpURLs objectForKey:@(error.code)];
        if(helpURL)
            [[NSWorkspace sharedWorkspace] openURL:helpURL];
    };
    
    if(player.shuffleMode)
        [mPlaybackErrorBannerView showInView:oShuffleModeNowPlayingContainer];
    else
        [mPlaybackErrorBannerView showInView:oPlayQueueContainerView];
    
    if(!player.shuffleMode && !player.isPlaying)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self hideNowPlayingFromView];
        }];
    }
}

#pragma mark - Browser Delegate

- (void)browserView:(RKBrowserView *)browserView willMoveIntoLevel:(RKBrowserLevel *)newLevel fromLevel:(RKBrowserLevel *)oldLevel
{
	[oldLevel unbind:@"searchString"];
	
	self.searchString = newLevel.searchString;
	
	[newLevel bind:@"searchString" 
		  toObject:self 
	   withKeyPath:@"searchString" 
		   options:nil];
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		if(oLibraryBrowser.canGoBack)
		{
			[self showBackButton];
		}
		else
		{
			[self hideBackButton];
		}
	}];
}

- (void)browserView:(RKBrowserView *)browserView nonLeafItem:(id)item wasDoubleClickedInLevel:(RKBrowserLevel *)level
{
	NSArray *selectedSongs = [NSArray array];
	
	if([item isKindOfClass:[Song class]])
		selectedSongs = level.selectedItems;
	else if([item respondsToSelector:@selector(songs)])
		selectedSongs = [item songs];
    
	if(RK_FLAG_IS_SET([NSEvent modifierFlags], NSShiftKeyMask))
		[Player addSongsToPlayQueue:selectedSongs];
	else
		[Player playSongsImmediately:selectedSongs];
}

- (void)browserView:(RKBrowserView *)browserView hoverButtonForItem:(id)item wasClickedInLevel:(RKBrowserLevel *)level
{
	NSArray *selectedSongs = [NSArray array];
	
	if([item isKindOfClass:[Song class]])
		selectedSongs = @[item];
	else if([item respondsToSelector:@selector(songs)])
		selectedSongs = [item songs];
	
	if(RK_FLAG_IS_SET([NSEvent modifierFlags], NSShiftKeyMask))
		[Player addSongsToPlayQueue:selectedSongs];
	else
		[Player playSongsImmediately:selectedSongs];
}

#pragma mark - Table View Delegate

- (void)tableViewWasDoubleClicked:(NSTableView *)tableView
{
	if([tableView clickedRow] == -1)
		return;
	
	[player playSongsImmediately:[oPlayQueueArrayController selectedObjects]];
}

- (NSMenu *)tableView:(NSTableView *)tableView menuForRows:(NSIndexSet *)rows
{
	if([rows count] == 0)
		return nil;
	
	NSArray *songs = [[oPlayQueueArrayController arrangedObjects] objectsAtIndexes:rows];
	return [[MenuGenerator sharedGenerator] contextualMenuForLibraryItems:songs];
}

#pragma mark -

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pasteboard = [info draggingPasteboard];
	
	if([pasteboard canReadObjectForClasses:@[[Song class]] options:nil])
	{
		NSArray *songs = [pasteboard readObjectsForClasses:@[[Song class]] options:nil];
		if([info draggingSource] == oPlayQueueTableView)
		{
			NSUInteger insertionRow = row;
			if(insertionRow > [tableView numberOfRows] - 1)
				insertionRow = [tableView numberOfRows] - 1;
			
			for (Song *song in songs)
			{
				[oPlayQueueArrayController removeObject:song];
				[oPlayQueueArrayController insertObject:song atArrangedObjectIndex:insertionRow];
			}
		}
		else
		{
			NSUInteger insertionRow = row;
			for (Song *song in songs)
			{
				if(![[oPlayQueueArrayController arrangedObjects] containsObject:song])
				{
					[oPlayQueueArrayController insertObject:song atArrangedObjectIndex:insertionRow];
					insertionRow++;
				}
			}
		}
		
		return YES;
	}
	else if([pasteboard canReadObjectForClasses:@[[NSURL class]] options:nil])
	{
		NSArray *fileURLs = [pasteboard readObjectsForClasses:@[[NSURL class]] options:nil];
		NSMutableArray *songs = [NSMutableArray array];
		for (NSURL *fileURL in fileURLs)
		{
			EnumerateFilesInLocation(fileURL, ^(NSURL *songLocation) {
				Song *song = [[Song alloc] initWithLocation:songLocation];
				if(song)
					[songs addObject:song];
			});
		}
		
		NSUInteger insertionRow = row;
		for (Song *song in songs)
		{
			if(![[oPlayQueueArrayController arrangedObjects] containsObject:song])
			{
				[oPlayQueueArrayController insertObject:song atArrangedObjectIndex:insertionRow];
				insertionRow++;
			}
		}
		
		return YES;
	}
	
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard
{
	NSArray *draggedSongs = [[oPlayQueueArrayController arrangedObjects] objectsAtIndexes:rowIndexes];
	[pasteboard clearContents];
	[pasteboard writeObjects:draggedSongs];
	
	return YES;
}

#pragma mark -

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	Song *song = [[oPlayQueueArrayController arrangedObjects] objectAtIndex:row];
	if(song.isProtected && song.hasVideo)
	{
		return @"Pinna is unable to play protected video files at this time. Apple restricts playback of said files to iTunes and QuickTime Player.";
	}
	
	return nil;
}

- (void)tableView:(QueueTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	Song *song = [[oPlayQueueArrayController arrangedObjects] objectAtIndex:row];
    Song *previousSong = row > 0? [[oPlayQueueArrayController arrangedObjects] objectAtIndex:row - 1] : nil;
	NSInteger indexOfPlayingSong = player.isPlaying? [player.playQueue indexOfObject:player.playingSong] : -1;
	BOOL isRowPlaying = (row == indexOfPlayingSong);
	BOOL isRowSelected = [[tableView selectedRowIndexes] containsIndex:row];
	BOOL isRowDead = song.isProtected && song.hasVideo;
	BOOL isRowDimmed = ([[NSUserDefaults standardUserDefaults] integerForKey:@"AudioPlayer_numberOfRecentlyPlayedSongs"] > 0) && (row < indexOfPlayingSong);
    BOOL isRowHovered = (tableView.hoveredUponRow == row);
	
    NSString *rawDisplayString = nil;
    if(!isRowHovered && previousSong && [song.artist isEqualToString:previousSong.artist])
        rawDisplayString = [NSString stringWithFormat:@"%@", song.name];
    else
        rawDisplayString = [NSString stringWithFormat:@"%@   %@", song.name, song.artist];
	NSMutableAttributedString *displayString = [RKBrowserLevel formatBrowserTextForDisplay:rawDisplayString
																				isSelected:isRowSelected || isRowPlaying
																			 dividerString:@"   "];
	
	NSRange rangeOfFirstSegment;
	[displayString attributesAtIndex:0 effectiveRange:&rangeOfFirstSegment];
	
	[displayString addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:11.0] range:rangeOfFirstSegment];
	
	if(!isRowSelected && !isRowPlaying)
	{
		if(isRowDead)
		{
			[displayString addAttribute:NSForegroundColorAttributeName
								  value:[NSColor colorWithCalibratedRed:0.36 green:0.00 blue:0.00 alpha:1.00]
								  range:rangeOfFirstSegment];
		}
		else if(isRowDimmed)
		{
			[displayString addAttribute:NSForegroundColorAttributeName
								  value:[NSColor colorWithDeviceWhite:0.40 alpha:1.0]
								  range:rangeOfFirstSegment];
		}
	}
	
	[cell setAttributedStringValue:displayString];
	
	
	if(isRowPlaying && !isRowSelected)
	{
		[cell setBackgroundGradient:_PlayingSongBackgroundGradient];
	}
	else
	{
		[cell setBackgroundGradient:nil];
	}
}

#pragma mark -

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonImageForRow:(NSInteger)row
{
	Library *library = [Library sharedLibrary];
	Song *song = [[oPlayQueueArrayController arrangedObjects] objectAtIndex:row];
	
	if([library isSongLovable:song])
	{
		if([library isSongBeingLovedOrUnloved:song])
			return [NSImage imageNamed:@"LoveItemButton_Busy"];
		
		if([library isSongLoved:song])
			return [NSImage imageNamed:@"LoveItemButton_Full"];
		
		return [NSImage imageNamed:@"LoveItemButton"];
	}
	
	return nil;
}

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonPressedImageForRow:(NSInteger)row
{
	Library *library = [Library sharedLibrary];
	Song *song = [[oPlayQueueArrayController arrangedObjects] objectAtIndex:row];
	
	if([library isSongLovable:song])
	{
		if([library isSongBeingLovedOrUnloved:song])
			return [NSImage imageNamed:@"LoveItemButton_Busy"];
		
		if([library isSongLoved:song])
			return [NSImage imageNamed:@"LoveItemButton_Full_Pressed"];
		
		return [NSImage imageNamed:@"LoveItemButton_Pressed"];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView hoverButtonWasClickedAtRow:(NSInteger)row
{
	Library *library = [Library sharedLibrary];
	Song *song = [[oPlayQueueArrayController arrangedObjects] objectAtIndex:row];
	
	if(![library isSongLovable:song])
		return;
	
    if(![RKConnectivityManager defaultInternetConnectivityManager].isConnected)
    {
        NSString *action = [library isSongLoved:song]? @"unlove" : @"love";
        
        [[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Cannot %@ song", action]
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"An internet connection is required to %@ songs", action] runModal];
        
        return;
    }
    
	if([library isSongLoved:song])
	{
		[[library unloveExFMSong:song] then:^(id result) {
            
        } otherwise:^(NSError *error) {
            [self presentLibraryError:error];
        }];
	}
	else
	{
		[[library loveExFMSong:song] then:^(id result) {
            
        } otherwise:^(NSError *error) {
            [self presentLibraryError:error];
        }];
	}
}

#pragma mark - Split View Delegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
	return ![view isEqualTo:[[splitView subviews] lastObject]];
}

#pragma mark - Window Delegate

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	if([[RKAnimator animator] isAnimating:sender])
		return [sender frame].size;
	
	return frameSize;
}

- (BOOL)window:(NSWindow *)window wasRotatedWithEvent:(NSEvent *)event
{
	NSDate *dateOfLastCall = [self associatedValueForKey:@"dateOfLastCall"];
	
	if(!dateOfLastCall ||
	   [[NSDate date] timeIntervalSinceDate:dateOfLastCall] > 1.0)
	{
		if([event rotation] >= 0.0)
		{
			[self previousTrack:nil];
		}
		else
		{
			[self nextTrack:nil];
		}
		
		[self setAssociatedValue:[NSDate date] forKey:@"dateOfLastCall"];
	}
	
	return YES;
}

@end
