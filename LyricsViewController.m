//
//  LyricsViewController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/10/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "LyricsViewController.h"
#import <WebKit/WebKit.h>
#import "AudioPlayer.h"
#import "LyricsCache.h"
#import "Song.h"

@interface LyricsViewController () <DOMEventListener>

@end

@implementation LyricsViewController

- (void)dealloc
{
	[Player removeObserver:self forKeyPath:@"playingSong"];
}

- (id)init
{
	return [super initWithNibName:@"Lyrics" bundle:nil];
}

- (void)loadView
{
	[super loadView];
	
	//Setup the lyrics
	NSURL *lyricsViewLocation = [[NSBundle mainBundle] URLForResource:@"Lyrics" withExtension:@"html"];
	[oLyricsWebView setUIDelegate:self];
	[oLyricsWebView setFrameLoadDelegate:self];
	[oLyricsWebView setEditingDelegate:self];
	[oLyricsWebView setShouldCloseWithWindow:NO];
	[oLyricsWebView setDrawsBackground:NO];
	[[oLyricsWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:lyricsViewLocation]];
	
	[Player addObserver:self forKeyPath:@"playingSong" options:0 context:NULL];
}

#pragma mark -

- (void)update
{
	if(mIsEditing)
		[self save:nil];
	
	mCurrentSong = Player.playingSong;
	
	DOMDocument *lyricsDocument = [[oLyricsWebView mainFrame] DOMDocument];
	DOMHTMLElement *lyricsElement = (DOMHTMLElement *)[lyricsDocument getElementById:@"lyrics"];
	
	NSString *cachedLyrics = [[LyricsCache sharedLyricsCache] lyricsForSong:mCurrentSong];
	if(cachedLyrics)
		lyricsElement.innerText = cachedLyrics;
	else
		lyricsElement.innerText = NSLocalizedString(@"No Lyrics", @"");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if((object == Player) && [keyPath isEqualToString:@"playingSong"])
	{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self update];
		}];
	}
}

#pragma mark - Actions

- (IBAction)save:(id)sender
{
	DOMDocument *lyricsDocument = [[oLyricsWebView mainFrame] DOMDocument];
	DOMHTMLElement *lyricsElement = (DOMHTMLElement *)[lyricsDocument getElementById:@"lyrics"];
	
	NSString *lyrics = lyricsElement.innerText;
	
	[lyricsElement blur];
	
	[[LyricsCache sharedLyricsCache] cacheLyrics:lyrics forSong:mCurrentSong];
}

#pragma mark - Web View

- (void)handleEvent:(DOMEvent *)event
{
	DOMDocument *lyricsDocument = [[oLyricsWebView mainFrame] DOMDocument];
	DOMHTMLElement *lyricsElement = (DOMHTMLElement *)[lyricsDocument getElementById:@"lyrics"];
	
	if([event.type isEqualToString:@"focus"])
	{
		if([lyricsElement.innerText isEqualToString:NSLocalizedString(@"No Lyrics", @"")])
			lyricsElement.innerText = @"";
	}
	else if([event.type isEqualToString:@"blur"])
	{
		if([lyricsElement.innerText isEqualToString:@""])
			lyricsElement.innerText = NSLocalizedString(@"No Lyrics", @"");
		
		[self save:nil];
	}
}

#pragma mark -

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	if(frame == [sender mainFrame])
	{
		DOMDocument *lyricsDocument = [[oLyricsWebView mainFrame] DOMDocument];
		DOMHTMLElement *lyricsElement = (DOMHTMLElement *)[lyricsDocument getElementById:@"lyrics"];
		[lyricsElement addEventListener:@"focus" listener:self useCapture:NO];
		[lyricsElement addEventListener:@"blur" listener:self useCapture:NO];
		
		[self update];
	}
}

- (BOOL)webView:(WebView *)sender doCommandBySelector:(SEL)action
{
	if(action == @selector(paste:))
	{
		[sender pasteAsPlainText:nil];
		
		return YES;
	}
	
	return NO;
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	return RKCollectionFilterToArray(defaultMenuItems, ^BOOL(NSMenuItem *item) {
		NSUInteger tag = [item tag];
		return !((tag >= WebMenuItemTagOpenLinkInNewWindow && tag <= WebMenuItemTagOpenFrameInNewWindow) || 
				 (tag >= WebMenuItemTagGoBack && tag <= WebMenuItemTagReload));
	});
}

- (NSUInteger)webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo
{
	return WebDragDestinationActionNone;
}

@end
