//
//  AlbumsBrowserLevel.m
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 2/12/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "AlbumsBrowserLevel.h"

#import "RKBorderlessWindow.h"

#import "Library.h"
#import "Album.h"
#import "Artist.h"
#import "ArtworkCache.h"
#import "MenuGenerator.h"

#import "RKBrowserView.h"
#import "SongsBrowserLevel.h"

@implementation AlbumsBrowserLevel

- (id)init
{
	if((self = [super init]))
	{
		mLibrary = [Library sharedLibrary];
	}
	
	return self;
}

#pragma mark - Providing Content

- (NSString *)title
{
	return mParentArtist.name ?: @"Albums";
}

@synthesize parentArtist = mParentArtist;

+ (NSSet *)keyPathsForValuesAffectingContents
{
	return [NSSet setWithObjects:@"mLibrary.albums", @"parentArtist", nil];
}

- (NSArray *)contents
{
	NSArray *albums = mLibrary.albums;
	if(mParentArtist)
		albums = [albums filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"artist == %@", mParentArtist]];
	
	return albums;
}

#pragma mark -

- (void)setSearchString:(NSString *)searchString
{
	super.searchString = searchString;
	
	if(searchString)
		self.filterPredicate = [Album searchPredicateForQueryString:searchString];
	else
		self.filterPredicate = nil;
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

- (void)levelRowCell:(RKBrowserIconTextFieldCell *)cell willBeDisplayedForItem:(Album *)item atRow:(NSUInteger)index
{
	BOOL isSelected = [self.selectedItemIndexes containsIndex:index];
	NSString *artistName = item.artist.name;
	if([artistName hasSuffix:kCompilationArtistMarker])
		artistName = kCompilationPlaceholderName;
	
	NSString *string = [NSString stringWithFormat:@"%@\n%@", item.name, artistName];
	
	NSAttributedString *displayString = [RKBrowserLevel formatBrowserTextForDisplay:string isSelected:isSelected dividerString:@"\n"];
	[cell setAttributedStringValue:displayString];
	
	NSImage *artworkImage = nil;
    if([[self.parentBrowser window] inLiveResize])
		artworkImage = [NSImage imageNamed:@"NoArtwork"];
    else
		artworkImage = [[ArtworkCache sharedArtworkCache] artworkForAlbum:item] ?: [NSImage imageNamed:@"NoArtwork"];
    [artworkImage setSize:NSMakeSize(32.0, 32.0)];
    [cell setImage:artworkImage];
	[cell setStylizesImage:YES];
}

- (NSImage *)hoverButtonImageForItem:(id)item
{
	return [NSImage imageNamed:@"PlayItemButton"];
}

- (NSImage *)hoverButtonPressedImageForItem:(id)item
{
	return [NSImage imageNamed:@"PlayItemButton_Pressed"];
}

#pragma mark -

- (void)levelWillBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	[super levelWillBecomeVisibleInBrowser:browserView];
	[[ArtworkCache sharedArtworkCache] beginCacheAccess];
}

- (void)levelWasRemovedFromBrowser:(RKBrowserView *)browserView
{
	[super levelWasRemovedFromBrowser:browserView];
	[[ArtworkCache sharedArtworkCache] endCacheAccess];
}

#pragma mark - Child Levels

- (BOOL)isChildLevelAvailableForItem:(Album *)item
{
	return YES;
}

- (RKBrowserLevel *)childBrowserLevelForItem:(Album *)item
{
	SongsBrowserLevel *songLevel = [SongsBrowserLevel new];
	songLevel.parent = item;
	
	return songLevel;
}

#pragma mark - Pasteboard

- (BOOL)writeLevelItems:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard
{
	[pasteboard clearContents];
	[pasteboard writeObjects:[rows valueForKeyPath:@"@unionOfArrays.songs"]];
	
	return YES;
}

@end
