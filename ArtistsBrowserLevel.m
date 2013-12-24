//
//  ArtistsBrowserLevel.m
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 2/12/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "ArtistsBrowserLevel.h"

#import "MenuGenerator.h"

#import "Library.h"

#import "Artist.h"
#import "Album.h"
#import "Song.h"

#import "AlbumsBrowserLevel.h"
#import "SongsBrowserLevel.h"

@implementation ArtistsBrowserLevel

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
	return @"Artists";
}

+ (NSSet *)keyPathsForValuesAffectingContents
{
	return [NSSet setWithObjects:@"mLibrary.artists", nil];
}

- (NSArray *)contents
{
	return mLibrary.artists;
}

#pragma mark -

- (void)setSearchString:(NSString *)searchString
{
	super.searchString = searchString;
	
	if(searchString)
		self.filterPredicate = [Artist searchPredicateForQueryString:searchString];
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

- (void)levelRowCell:(RKBrowserIconTextFieldCell *)cell willBeDisplayedForItem:(Artist *)item atRow:(NSUInteger)index
{
	BOOL isSelected = [self.selectedItemIndexes containsIndex:index];
	
	NSAttributedString *displayString = [RKBrowserLevel formatBrowserTextForDisplay:item.name ?: @"" isSelected:isSelected dividerString:@"\b"];
	[cell setAttributedStringValue:displayString];
}

- (NSImage *)hoverButtonImageForItem:(id)item
{
	return [NSImage imageNamed:@"PlayItemButton"];
}

- (NSImage *)hoverButtonPressedImageForItem:(id)item
{
	return [NSImage imageNamed:@"PlayItemButton_Pressed"];
}

#pragma mark - Child Levels

- (BOOL)isChildLevelAvailableForItem:(Artist *)item
{
	return YES;
}

- (RKBrowserLevel *)childBrowserLevelForItem:(Artist *)item
{
	if([item.albums count] > 1)
	{
		AlbumsBrowserLevel *albumBrowserLevel = [AlbumsBrowserLevel new];
		albumBrowserLevel.parentArtist = item;
		return albumBrowserLevel;
	}
	
	SongsBrowserLevel *songBrowserLevel = [SongsBrowserLevel new];
	songBrowserLevel.parent = item;
	return songBrowserLevel;
}

#pragma mark - Pasteboard

- (BOOL)writeLevelItems:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard
{
	[pasteboard clearContents];
	[pasteboard writeObjects:[rows valueForKeyPath:@"@unionOfArrays.albums.@unionOfArrays.songs"]];
	
	return YES;
}

@end
