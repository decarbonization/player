//
//  SongsBrowserLevel.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/1/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "SongsBrowserLevel.h"

#import "RKBorderlessWindow.h"

#import "Library.h"
#import "ExfmSession.h"
#import "RKBrowserView.h"
#import "RKBrowserLevelInternal.h"
#import "MenuGenerator.h"
#import "ArtworkCache.h"
#import "PlaylistsBrowserLevel.h"

#import "Song.h"
#import "Artist.h"
#import "Album.h"
#import "Playlist.h"

@implementation SongsBrowserLevel

- (void)dealloc
{
	if(mIsObservingPlaylistChanges)
		[self stopObservingForPlaylistChanges];
}

- (id)init
{
	if((self = [super init]))
	{
		mIsValid = YES;
		mLibrary = [Library sharedLibrary];
	}
	
	return self;
}

#pragma mark - Support for Changing Playlists

- (void)beginObservingForPlaylistChanges
{
	if(!mIsObservingPlaylistChanges)
	{
		[self.parentBrowser addObserver:self forKeyPath:@"contents" options:0 context:NULL];
		mIsObservingPlaylistChanges = YES;
	}
}

- (void)stopObservingForPlaylistChanges
{
	if(mIsObservingPlaylistChanges)
	{
		[self.parentBrowser removeObserver:self forKeyPath:@"contents"];
		mIsObservingPlaylistChanges = NO;
	}
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == self.parentBrowser && [keyPath isEqualToString:@"contents"])
	{
		NSString *selectedPlaylistName = [mParent name];
		Playlist *selectedPlaylist = RKCollectionFindFirstMatch(self.cachedPreviousLevel.contents, ^(Playlist *playlist) {
			return [playlist.name isEqualToString:selectedPlaylistName];
		});
		
		//This has to be run after oPlaylistsArrayController has had
		//a chance to pick up the changes we just observed.
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			if(selectedPlaylist)
			{
				[self willChangeValueForKey:@"parent"];
				mParent = selectedPlaylist;
				[self didChangeValueForKey:@"parent"];
			}
			else
			{
				[self willChangeValueForKey:@"isValid"];
				mIsValid = NO;
				[self didChangeValueForKey:@"isValid"];
				
				[self.parentBrowser goBack:nil];
			}
		}];
	}
}

#pragma mark - Providing Content

- (NSString *)title
{
	return [mParent name] ?: @"Songs";
}

- (void)setParent:(id)parent
{
	[self stopObservingForPlaylistChanges];
	
	if(parent)
	{
		if([parent isKindOfClass:[Playlist class]])
		{
			[self beginObservingForPlaylistChanges];
			
			mFetchPredicate = nil;
		}
		else if([parent isKindOfClass:[Artist class]])
		{
			mFetchPredicate = [NSPredicate predicateWithFormat:@"artist == %@", [parent name]];
		}
		else if([parent isKindOfClass:[Album class]])
		{
			Album *album = parent;
			if(album.isCompilation)
				mFetchPredicate = [NSPredicate predicateWithFormat:@"isCompilation == YES && album == %@", album.name];
			else
				mFetchPredicate = [NSPredicate predicateWithFormat:@"albumArtist == %@ && album == %@", album.artist.name, album.name];
		}
		else
		{
			[NSException raise:NSInternalInconsistencyException 
						format:@"Object of unknown type (%@) assigned to Song's parent.", NSStringFromClass([parent class])];
		}
	}
	else
	{
		mFetchPredicate = nil;
	}
	
	mParent = parent;
}

- (id)parent
{
	return mParent;
}

+ (NSSet *)keyPathsForValuesAffectingContents
{
	return [NSSet setWithObjects:@"mLibrary.songs", @"parent", nil];
}

- (NSArray *)contents
{
	if([mParent isKindOfClass:[Playlist class]])
		return [(Playlist *)mParent songs];
	
	NSArray *songs = mLibrary.songs;
	if(mFetchPredicate)
		songs = [songs filteredArrayUsingPredicate:mFetchPredicate];
	
	return songs;
}

#pragma mark -

- (void)setSearchString:(NSString *)searchString
{
	super.searchString = searchString;
	
	if(searchString)
		self.filterPredicate = [Song searchPredicateForQueryString:searchString];
	else
		self.filterPredicate = nil;
}

#pragma mark -

- (BOOL)allowsMultipleSelection
{
	return YES;
}

- (BOOL)isValid
{
	return mIsValid;
}

#pragma mark -

@synthesize showsArtwork = mShowsArtwork;

#pragma mark - Display

- (void)levelWillBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	[super levelWillBecomeVisibleInBrowser:browserView];
	
	if(self.showsArtwork)
	{
		[[ArtworkCache sharedArtworkCache] beginCacheAccess];
	}
}

- (void)levelWasRemovedFromBrowser:(RKBrowserView *)browserView
{
	[super levelWasRemovedFromBrowser:browserView];
    
	if(self.showsArtwork)
	{
		[[ArtworkCache sharedArtworkCache] endCacheAccess];
	}
}

#pragma mark -

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

- (void)levelRowCell:(RKBrowserIconTextFieldCell *)cell willBeDisplayedForItem:(Song *)item atRow:(NSUInteger)index
{
	BOOL isSelected = [self.selectedItemIndexes containsIndex:index];
	BOOL isRowDead = item.isProtected && item.hasVideo;
	
	NSString *string = [NSString stringWithFormat:@"%@\n“%@” by %@", item.name, item.album, item.artist];
	NSMutableAttributedString *displayString = [[RKBrowserLevel formatBrowserTextForDisplay:string
																				 isSelected:isSelected
																			  dividerString:@"\n"] mutableCopy];
	
	if(!isSelected && isRowDead)
	{
		NSRange rangeOfFirstSegment;
		[displayString attributesAtIndex:0 effectiveRange:&rangeOfFirstSegment];
		
		[displayString addAttribute:NSForegroundColorAttributeName
							  value:[NSColor colorWithCalibratedRed:0.36 green:0.00 blue:0.00 alpha:1.00]
							  range:rangeOfFirstSegment];
	}
	
	[cell setAttributedStringValue:displayString];
	
	if(self.showsArtwork)
	{
		NSImage *artworkImage = nil;
		if([[self.parentBrowser window] inLiveResize])
			artworkImage = [NSImage imageNamed:@"NoArtwork"];
		else
			artworkImage = [[ArtworkCache sharedArtworkCache] artworkForSong:item] ?: [NSImage imageNamed:@"NoArtwork"];
		[artworkImage setSize:NSMakeSize(32.0, 32.0)];
		[cell setImage:artworkImage];
		[cell setStylizesImage:YES];
	}
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

- (void)handleHoverButtonClickForItem:(Song *)song
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

@end
