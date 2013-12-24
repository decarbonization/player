//
//  DiscoveryBrowserLevel.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/19/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "ExploreBrowserLevel.h"
#import "AppDelegate.h"
#import "PreferencesWindow.h"
#import "MenuGenerator.h"

#import "RKBrowserView.h"
#import "RKBrowserIconTextFieldCell.h"

#import "Song.h"
#import "Library.h"
#import "ExfmSession.h"

static NSString *const kTrendingTagUserDefaultsKey = @"ExFM_trendingTag";

@implementation ExploreBrowserLevel

- (void)dealloc
{
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kTrendingTagUserDefaultsKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
	if((self = [super init]))
	{
		mLibrary = [Library sharedLibrary];
		mResults = [NSArray array];
		mCachedTrending = [NSArray array];
		
		mArtworkCache = [NSCache new];
		[mArtworkCache setName:@"com.roundabout.pinna.ExploreBrowserLevel.mArtworkCache"];
		[mArtworkCache setCountLimit:25];
		
		mArtworkBeingDownloaded = [NSMutableSet set];
		
		mArtworkDownloadQueue = [NSOperationQueue new];
		[mArtworkDownloadQueue setMaxConcurrentOperationCount:2];
		[mArtworkDownloadQueue setName:@"com.roundabout.pinna.ExploreBrowserLevel.mArtworkDownloadQueue"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(exFMSessionDidUpdateLovedSongs:)
													 name:ExfmSessionUpdatedCachedLovedSongsNotification
												   object:nil];
		
		[[NSUserDefaults standardUserDefaults] addObserver:self
												forKeyPath:kTrendingTagUserDefaultsKey
												   options:0
												   context:NULL];
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == [NSUserDefaults standardUserDefaults] && [keyPath isEqualToString:kTrendingTagUserDefaultsKey])
	{
		[self updateTrending];
	}
}

#pragma mark - Tools

- (NSArray *)songsFromExFMData:(NSArray *)exFMSongs
{
	NSArray *allSongsInLibrary = mLibrary.songs;
	NSArray *reducedExFMSongs = [self reduceDuplicatesInResults:exFMSongs];
	return [RKCollectionMapToOrderedSet(reducedExFMSongs, ^id(NSDictionary *track) {
		Song *song = [[Song alloc] initWithTrackDictionary:track source:kSongSourceExfm];
		Song *possibleLocalEquivalentSong = BestMatchForSongInArray(song, allSongsInLibrary);
		if(possibleLocalEquivalentSong)
		{
			if(possibleLocalEquivalentSong.sourceIdentifier && song.sourceIdentifier)
				[mLibrary registerExternalAlternateIdentifier:song.sourceIdentifier forSong:possibleLocalEquivalentSong];
			
			return possibleLocalEquivalentSong;
		}
		
		return song;
	}) array];
}

- (NSArray *)reduceDuplicatesInResults:(NSArray *)exFMSongs
{
	NSString *(^hashEntry)(NSDictionary *) = ^(NSDictionary *songResult) {
		NSString *title = RKFilterOutNSNull([songResult objectForKey:@"title"]);
		NSString *artist = RKFilterOutNSNull([songResult objectForKey:@"artist"]);
		return RKGenerateIdentifierForStrings(@[title ?: @"", artist ?: @""]);
	};
	
	NSMutableDictionary *hash = [NSMutableDictionary dictionary];
	
	for (NSDictionary *exFMSong in exFMSongs)
	{
		NSString *songKey = hashEntry(exFMSong);
		NSDictionary *match = [hash objectForKey:songKey];
		if(match)
		{
			NSString *leftDateString = RKFilterOutNSNull([exFMSong objectForKey:@"last_loved"]);
			NSString *rightDateString = RKFilterOutNSNull([match objectForKey:@"last_loved"]);
			if(!leftDateString || rightDateString)
				continue;
			
			NSDate *leftDate = [NSDate dateWithString:leftDateString];
			NSDate *rightDate = [NSDate dateWithString:rightDateString];
			if([leftDate compare:rightDate] == NSOrderedDescending)
			{
				[hash setObject:exFMSong forKey:songKey];
			}
		}
		else
		{
			[hash setObject:exFMSong forKey:songKey];
		}
	}
	
	return [[hash allValues] sortedArrayUsingDescriptors:@[
                [NSSortDescriptor sortDescriptorWithKey:@"loved_count" ascending:NO],
            ]];
}

#pragma mark - Providing Content

+ (NSSet *)keyPathsForValuesAffectingTitle
{
	return [NSSet setWithObjects:@"searchString", nil];
}

- (NSString *)title
{
	if(self.searchString)
		return @"Results";
	
	return @"Trending ▾";
}

+ (NSSet *)keyPathsForValuesAffectingContents
{
	return [NSSet setWithObjects:@"searchString", nil];
}

- (NSArray *)contents
{
	if(self.searchString)
		return mResults;
	
	return mCachedTrending;
}

#pragma mark -

- (void)setSearchString:(NSString *)searchString
{
	if([searchString isEqualToString:self.searchString])
		return;
	
	super.searchString = searchString;
	
	if(searchString)
	{
		RKPromise *songsPromise = [[ExfmSession defaultSession] searchSongsWithQuery:searchString offset:0];
		[songsPromise then:^(NSDictionary *response) {
			//It's possible the user has started multiple queries at once
			//without being aware of it. We only want to display the latest
			//query results.
			if(![self.searchString isEqualToString:searchString])
				return;
			
			[self willChangeValueForKey:@"contents"];
			mResults = [self songsFromExFMData:[response objectForKey:@"songs"]];
			[self didChangeValueForKey:@"contents"];
			
			mResultsOffset = 50;
		} otherwise:^(NSError *error) {
			//It's possible the user has started multiple queries at once
			//without being aware of it. We only want to display the latest
			//query results.
			if(![self.searchString isEqualToString:searchString])
				return;
			
			mResultsOffset = 0;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:LibraryErrorDidOccurNotification
																object:self
															  userInfo:@{@"error": error}];
		}];
	}
	else
	{
		[self willChangeValueForKey:@"contents"];
		mResults = [NSArray array];
		[self didChangeValueForKey:@"contents"];
	}
}

+ (NSSet *)keyPathsForValuesAffectingIsSearching
{
	return [NSSet setWithObjects:@"searchString", nil];
}

- (BOOL)isSearching
{
	return (self.searchString != nil);
}

#pragma mark -

- (void)updateTrending
{
    RKPromise *trendingPromise;
    NSString *trendingTag = [[NSUserDefaults standardUserDefaults] stringForKey:kTrendingTagUserDefaultsKey];
    if(trendingTag)
        trendingPromise = [[ExfmSession defaultSession] trendingSongsWithTag:trendingTag];
    else
        trendingPromise = [[ExfmSession defaultSession] overallTrendingSongs];
    
    [trendingPromise then:^(id response) {
        NSArray *trending = [self songsFromExFMData:[response objectForKey:@"songs"]];
        
        [self willChangeValueForKey:@"contents"];
        mCachedTrending = trending;
        [self didChangeValueForKey:@"contents"];
        
    } otherwise:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LibraryErrorDidOccurNotification
                                                            object:self
                                                          userInfo:@{@"error": error}];
    }];
}

- (void)exFMSessionDidUpdateLovedSongs:(NSNotification *)notification
{
	if(!self.searchString)
		[self updateTrending];
}

- (void)levelWillBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	[self updateTrending];
	
	mTrendingUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:(RK_TIME_MINUTE * 5.0)
															target:self
														  selector:@selector(updateTrending)
														  userInfo:nil
														   repeats:YES];
}

- (void)levelWillBeRemovedFromBrowser:(RKBrowserView *)browserView
{
	[mTrendingUpdateTimer invalidate];
	mTrendingUpdateTimer = nil;
}

#pragma mark -

- (BOOL)allowsMultipleSelection
{
	return YES;
}

- (BOOL)isValid
{
	return YES;
}

#pragma mark - Display

- (CGFloat)rowHeight
{
	return 40.0;
}

- (NSMenu *)contextualMenuForItems:(NSArray *)items
{
	if([items count] == 0)
		return nil;
	
	return [[MenuGenerator sharedGenerator] contextualMenuForLibraryItems:items];
}

- (NSImage *)artworkImageForSong:(Song *)song
{
	NSImage *artwork = [mArtworkCache objectForKey:song.universalIdentifier];
	if(artwork)
		return artwork;
	
	if(![mArtworkBeingDownloaded containsObject:song.universalIdentifier])
	{
		[mArtworkDownloadQueue addOperationWithBlock:^{
			NSURL *remoteArtworkLocation = [song.remoteArtworkLocations objectForKey:@"small"];
			if(!remoteArtworkLocation)
				return;
			
			NSImage *artworkImage = [[NSImage alloc] initWithContentsOfURL:remoteArtworkLocation];
			if(artworkImage) //Can be nil.
			{
				[mArtworkCache setObject:artworkImage forKey:song.universalIdentifier];
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					[mArtworkBeingDownloaded removeObject:song.universalIdentifier];
					
					[self willChangeValueForKey:@"contents"];
					[self didChangeValueForKey:@"contents"];
				}];
			}
		}];
	}
	
	return [NSImage imageNamed:@"NoArtwork"];
}

- (void)levelRowCell:(RKBrowserIconTextFieldCell *)cell willBeDisplayedForItem:(Song *)item atRow:(NSUInteger)index
{
	BOOL isSelected = [self.selectedItemIndexes containsIndex:index];
	NSString *string = [NSString stringWithFormat:@"%@\n“%@” by %@", item.name, item.album, item.artist];
	
	NSAttributedString *displayString = [RKBrowserLevel formatBrowserTextForDisplay:string isSelected:isSelected dividerString:@"\n"];
	[cell setAttributedStringValue:displayString];
	
	NSImage *artworkImage = [self artworkImageForSong:item];
    [artworkImage setSize:NSMakeSize(32.0, 32.0)];
    [cell setImage:artworkImage];
	[cell setStylizesImage:YES];
}

- (NSImage *)hoverButtonImageForItem:(Song *)item
{
	if([mLibrary isSongLovable:item])
	{
		if([mLibrary isSongBeingLovedOrUnloved:item])
			return [NSImage imageNamed:@"LoveItemButton_Busy"];
		
		if([mLibrary isSongLoved:item])
			return [NSImage imageNamed:@"LoveItemButton_Full"];
		
		return [NSImage imageNamed:@"LoveItemButton"];
	}
	
	return nil;
}

- (NSImage *)hoverButtonPressedImageForItem:(Song *)item
{
	if([mLibrary isSongLovable:item])
	{
		if([mLibrary isSongBeingLovedOrUnloved:item])
			return [NSImage imageNamed:@"LoveItemButton_Busy"];
		
		if([mLibrary isSongLoved:item])
			return [NSImage imageNamed:@"LoveItemButton_Full_Pressed"];
		
		return [NSImage imageNamed:@"LoveItemButton_Pressed"];
	}
	
	return nil;
}

#pragma mark - Pasteboard

- (BOOL)writeLevelItems:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard
{
	[pasteboard clearContents];
	[pasteboard writeObjects:rows];
	
	return YES;
}

#pragma mark - Callbacks

- (void)levelDidScrollToEndOfContents
{
	NSString *searchString = self.searchString;
	
	if(mIsLoadingMoreResults || !searchString)
		return;
	
	mIsLoadingMoreResults = YES;
	
	RKPromise *moreSongsPromise = [[ExfmSession defaultSession] searchSongsWithQuery:searchString offset:mResultsOffset];
	[moreSongsPromise then:^(NSDictionary *response) {
		//It's possible the user has started multiple queries at once
		//without being aware of it. We only want to display the latest
		//query results.
		if(![self.searchString isEqualToString:searchString])
		{
			mIsLoadingMoreResults = NO;
			return;
		}
		
		[self willChangeValueForKey:@"contents"];
		NSArray *moreResults = [self songsFromExFMData:[response objectForKey:@"songs"]];
		mResults = [mResults arrayByAddingObjectsFromArray:moreResults];
		[self didChangeValueForKey:@"contents"];
		
		mResultsOffset += 50;
		
		mIsLoadingMoreResults = NO;
	} otherwise:^(NSError *error) {
		mIsLoadingMoreResults = NO;
		
		//It's possible the user has started multiple queries at once
		//without being aware of it. We only want to display the latest
		//query results.
		if(![self.searchString isEqualToString:searchString])
			return;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:LibraryErrorDidOccurNotification
                                                            object:self
                                                          userInfo:@{@"error": error}];
	}];
}

- (void)handleHoverButtonClickForItem:(Song *)song
{
	if([ExfmSession defaultSession].isAuthorized)
	{
		if(![mLibrary isSongLovable:song] || [mLibrary isSongBeingLovedOrUnloved:song])
			return;
        
        if(![RKConnectivityManager defaultInternetConnectivityManager].isConnected)
        {
            NSString *action = [mLibrary isSongLoved:song]? @"unlove" : @"love";
            
            [[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Cannot %@ song", action]
                             defaultButton:@"OK"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"An internet connection is required to %@ songs", action] runModal];
            
            return;
        }
		
		if([mLibrary isSongLoved:song])
		{
			[[mLibrary unloveExFMSong:song] then:^(id result) {
				[self.parentBrowser setNeedsDisplay:YES];
			} otherwise:^(NSError *error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:LibraryErrorDidOccurNotification
                                                                    object:self
                                                                  userInfo:@{@"error": error}];
			}];
		}
		else
		{
			[[mLibrary loveExFMSong:song] then:^(id result) {
				[self.parentBrowser setNeedsDisplay:YES];
			} otherwise:^(NSError *error) {
				[[NSNotificationCenter defaultCenter] postNotificationName:LibraryErrorDidOccurNotification
                                                                    object:self
                                                                  userInfo:@{@"error": error}];
			}];
		}
		
		[self.parentBrowser setNeedsDisplay:YES];
	}
	else
	{
		NSInteger returnCode = [[NSAlert alertWithMessageText:@"An Exfm Account Is Required to Love Songs"
												defaultButton:@"More Info"
											  alternateButton:@"Cancel"
												  otherButton:nil
									informativeTextWithFormat:@""] runModal];
		if(returnCode == NSOKButton)
		{
			PreferencesWindow *preferencesWindow = [[NSApp delegate] preferencesWindow];
			[preferencesWindow showSocialPane];
			[preferencesWindow showWindow:nil];
		}
	}
}

@end
