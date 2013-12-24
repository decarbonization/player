//
//  NowPlaying.m
//  Pinna
//
//  Created by Peter MacWhinnie on 1/5/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "NowPlayingPane.h"

#import "ScrubbingBarView.h"

#import "MainWindow.h"
#import "LyricsViewController.h"

#import "RKAnimator.h"
#import "FileEnumerator.h"

#import "MainWindow.h"
#import "Song.h"

static NSString *const kScrubbingBarUseTimeRemainingDisplayStyleDefaultsKey = @"MainWindow_scrubbingBarUseTimeRemainingDisplayStyle";

static CGFloat const kArtworkNegativeSpace = 3.0;
static CGFloat const kArtworkContractedShowingSpace = 10.0;

@implementation NowPlayingPane

#pragma mark Internal Gunk

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithMainWindow:(MainWindow *)mainWindow
{
	NSParameterAssert(mainWindow);
	
	if((self = [super initWithNibName:@"NowPlayingPane" bundle:nil]))
	{
		mCanToggleArtwork = YES;
		
		mMainWindow = mainWindow;
		
		mLyricsController = [LyricsViewController new];
		mLyricsPopover = [NSPopover new];
		mLyricsPopover.appearance = NSPopoverAppearanceHUD;
		mLyricsPopover.behavior = NSPopoverBehaviorTransient;
		mLyricsPopover.contentViewController = mLyricsController;
		
		player = [AudioPlayer sharedAudioPlayer];
	}
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	oArtworkImageView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"NowPlayingBackgroundTexture"]];
	oArtworkImageView.imageShadow = RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.5], 5.0, NSMakeSize(0.0, -1.0));
	[oArtworkImageView bind:@"image" 
				   toObject:Player 
				withKeyPath:@"artwork" 
					options:@{NSNullPlaceholderBindingOption: [NSImage imageNamed:@"NoArtwork"]}];
	
	[oSongTitleLabel setFont:[NSFont fontWithName:@"MavenProMedium" size:13.0]];
	[oSongInfoLabel setFont:[NSFont fontWithName:@"MavenProRegular" size:12.0]];
	
	//Setup the scrubbing bar
	oScrubbingBar.useTimeRemainingDisplayStyle = [[NSUserDefaults standardUserDefaults] boolForKey:kScrubbingBarUseTimeRemainingDisplayStyleDefaultsKey];
	[[NSUserDefaults standardUserDefaults] bind:kScrubbingBarUseTimeRemainingDisplayStyleDefaultsKey 
									   toObject:oScrubbingBar 
									withKeyPath:@"useTimeRemainingDisplayStyle" 
										options:nil];
	
	[oScrubbingBar bind:@"duration" 
			   toObject:Player 
			withKeyPath:@"duration" 
				options:nil];
	
    __block NowPlayingPane *me = self;
	oScrubbingBar.action = ^{ Player.currentTime = me->oScrubbingBar.currentTime; };
	
	[Player addPulseObserver:self]; //The reference created by this method call is weak.
}
#pragma mark - Modes

@synthesize canToggleArtwork = mCanToggleArtwork;

#pragma mark -

- (CGFloat)heightOfInformationArea
{
	return NSHeight([oInformationAreaView frame]) + NSHeight([oShadowImageView frame]) + kArtworkContractedShowingSpace;
}

#pragma mark -

- (BOOL)isArtworkVisible
{
	return (NSHeight([[self view] frame]) > [self heightOfInformationArea]);
}

- (void)resetArtwork
{
	CGFloat minXOfShadow = NSMinX([oShadowImageView frame]);
	CGFloat heightOfInformationArea = NSHeight([oInformationAreaView frame]);
	
	NSRect initialArtworkViewFrame = [oArtworkImageView frame];
	initialArtworkViewFrame.size.height = NSWidth(initialArtworkViewFrame);
	initialArtworkViewFrame.origin.y = minXOfShadow - (NSHeight(initialArtworkViewFrame) - heightOfInformationArea - kArtworkContractedShowingSpace);
	
	[oArtworkImageView setFrame:initialArtworkViewFrame];
}

- (void)showArtwork
{
	if(self.isArtworkVisible)
		return;
	
	NSRect containingViewFrame = [[[self view] superview] frame];
	CGFloat heightOfShadow = NSHeight([oShadowImageView frame]);
	CGFloat heightOfInformationArea = NSHeight([oInformationAreaView frame]);
	
	NSRect targetFrame = [[self view] frame];
	targetFrame.size.height = NSHeight(containingViewFrame) + heightOfShadow;
	
	NSRect artworkImageViewTargetFrame = [oArtworkImageView frame];
	artworkImageViewTargetFrame.size.height = NSHeight(containingViewFrame) - (heightOfInformationArea - kArtworkNegativeSpace);
	artworkImageViewTargetFrame.origin.y = heightOfInformationArea - kArtworkNegativeSpace;
	
	oArtworkImageView.autoresizingMask = 0;
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction setFrame:targetFrame forTarget:[self view]];
        [transaction setFrame:artworkImageViewTargetFrame forTarget:oArtworkImageView];
    } completionHandler:^(BOOL didFinish) {
        oArtworkImageView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
        [mDelegate nowPlayingPaneDidShowArtwork:self];
    }];
}

- (void)hideArtwork
{
	if(!self.isArtworkVisible)
		return;
	
	CGFloat minXOfShadow = NSMinX([oShadowImageView frame]);
	CGFloat heightOfInformationArea = NSHeight([oInformationAreaView frame]);
	
	NSRect targetFrame = [[self view] frame];
	targetFrame.size.height = [self heightOfInformationArea]; 
	
	NSRect artworkImageViewTargetFrame = [oArtworkImageView frame];
	artworkImageViewTargetFrame.size.height = NSWidth(artworkImageViewTargetFrame);
	artworkImageViewTargetFrame.origin.y = minXOfShadow - (NSHeight(artworkImageViewTargetFrame) - heightOfInformationArea - kArtworkContractedShowingSpace);
	
	[self.delegate nowPlayingPaneWillHideArtwork:self];
	
	oArtworkImageView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction setFrame:targetFrame forTarget:[self view]];
        [transaction setFrame:artworkImageViewTargetFrame forTarget:oArtworkImageView];
    } completionHandler:^(BOOL didFinish) {
        [mDelegate nowPlayingPaneDidHideArtwork:self];
    }];
}

- (IBAction)toggleArtwork:(id)sender
{
	if(self.isArtworkVisible)
		[self hideArtwork];
	else
		[self showArtwork];
}

#pragma mark -

@synthesize delegate = mDelegate;

#pragma mark - Interface Hooks

- (void)audioPlayerPulseDidTick:(AudioPlayer *)audioPlayer
{
	oScrubbingBar.currentTime = audioPlayer.currentTime;
}

#pragma mark - Lyrics

- (BOOL)isLyricsVisible
{
	return mLyricsPopover.shown;
}

- (void)showLyrics
{
	if([self isLyricsVisible])
		return;
	
	[mLyricsPopover showRelativeToRect:NSZeroRect 
								ofView:oSongTitleLabel 
						 preferredEdge:NSMinYEdge];
}

- (void)hideLyrics
{
	if(![self isLyricsVisible])
		return;
	
	[mLyricsPopover close];
}

#pragma mark - Actions

- (IBAction)bringUpLyrics:(NSButton *)sender
{
	if([[NSApp currentEvent] clickCount] == 2)
	{
		[self showLyrics];
	}
}

#pragma mark - Chrome View Delegate

- (void)windowChromeViewWasClicked:(RKChromeView *)windowChromeView
{
	if(self.canToggleArtwork)
	{
		[self toggleArtwork:nil];
	}
}

- (NSDragOperation)windowChromeView:(RKChromeView *)chromeView validateDrop:(id <NSDraggingInfo>)info
{
	return NSDragOperationCopy;
}

- (BOOL)windowChromeView:(RKChromeView *)chromeView acceptDrop:(id <NSDraggingInfo>)info
{
	NSPasteboard *pasteboard = [info draggingPasteboard];
	
	NSArray *songs = nil;
	if([pasteboard canReadObjectForClasses:@[[Song class]] options:nil])
	{
		songs = [pasteboard readObjectsForClasses:@[[Song class]] options:nil];
	}
	else if([pasteboard canReadObjectForClasses:@[[NSURL class]] options:nil])
	{
		NSArray *fileURLs = [pasteboard readObjectsForClasses:@[[NSURL class]] options:nil];
		NSMutableArray *songsFromFiles = [NSMutableArray array];
		for (NSURL *fileURL in fileURLs)
		{
			EnumerateFilesInLocation(fileURL, ^(NSURL *songLocation) {
				Song *song = [[Song alloc] initWithLocation:songLocation];
				if(song)
					[songsFromFiles addObject:song];
			});
		}
		songs = songsFromFiles;
	}
	
	if(songs)
	{
		if(player.shuffleMode && [songs count] == 1)
		{
			NSDate *lastDropTime = [self associatedValueForKey:@"previousDropTimeInshuffleMode"];
			
			if(lastDropTime && ([[NSDate date] timeIntervalSinceDate:lastDropTime] <= 1.0))
			{
				player.shuffleMode = NO;
				[player addSongsToPlayQueue:songs];
			}
			else
			{
				player.nextShuffleSong = RKCollectionGetFirstObject(songs);
			}
			
			
			[self setAssociatedValue:[NSDate date] forKey:@"previousDropTimeInshuffleMode"];
		}
		else
		{
			[player addSongsToPlayQueue:songs];
		}
		
		
		return YES;
	}
	
	return NO;
}


@end
