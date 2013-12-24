//
//  PlaylistsBrowserLevel.m
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PlaylistsBrowserLevel.h"

#import "Playlist.h"
#import "Song.h"

#import "Library.h"
#import "ExfmSession.h"

#import "SongsBrowserLevel.h"
#import "FriendActivityBrowserLevel.h"

@implementation PlaylistsBrowserLevel

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    if((self = [super init]))
    {
        mLibrary = [Library sharedLibrary];
        
        mFriendActivityLevelPlaylist = [[Playlist alloc] initWithName:@"Recently Loved by Friends"
                                                                songs:[NSArray array]
                                                         playlistType:kPlaylistTypeFriendsLovedSongs];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(exfmSessionUpdatedCachedLovedSongsOfFriends:)
                                                     name:ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification
                                                   object:[ExfmSession defaultSession]];
    }
    
    return self;
}

#pragma mark -
#pragma mark Providing Content

- (NSString *)title
{
    return @"Playlists";
}

+ (NSSet *)keyPathsForValuesAffectingContents
{
    return [NSSet setWithObjects:@"mLibrary.playlists", nil];
}

- (NSArray *)contents
{
    if([ExfmSession defaultSession].isAuthorized && [mLibrary.playlists count] > 0)
    {
        NSMutableArray *playlists = [mLibrary.playlists mutableCopy];
        [playlists insertObject:mFriendActivityLevelPlaylist atIndex:1];
        return playlists;
    }
    
    return mLibrary.playlists;
}

#pragma mark -

- (void)setSearchString:(NSString *)searchString
{
    super.searchString = searchString;
    
    if(searchString)
        self.filterPredicate = [Playlist searchPredicateForQueryString:searchString];
    else
        self.filterPredicate = nil;
}

#pragma mark -

- (void)exfmSessionUpdatedCachedLovedSongsOfFriends:(NSNotification *)notification
{
    [self willChangeValueForKey:@"contents"];
    NSUInteger numberOfNewLovedSongsOfFriends = [ExfmSession defaultSession].numberOfNewFriendLoveActivities;
    if(numberOfNewLovedSongsOfFriends > 0)
        mFriendActivityLevelPlaylist.badge = [NSString stringWithFormat:@"%ld", numberOfNewLovedSongsOfFriends];
    else
        mFriendActivityLevelPlaylist.badge = nil;
    
    [self didChangeValueForKey:@"contents"];
}

#pragma mark -
#pragma mark Display

- (CGFloat)rowHeight
{
    return 40.0;
}

- (void)levelRowCell:(RKBrowserIconTextFieldCell *)cell willBeDisplayedForItem:(Playlist *)item atRow:(NSUInteger)index
{
    BOOL isSelected = [self.selectedItemIndexes containsIndex:index];
    
    NSString *title = nil;
    if(item.badge)
        title = [NSString stringWithFormat:@"%@ (%@)", item.name ?: @"", item.badge];
    else
        title = item.name ?: @"";
    
    NSAttributedString *displayString = [RKBrowserLevel formatBrowserTextForDisplay:title
                                                                         isSelected:isSelected
                                                                      dividerString:@"\b"];
    [cell setAttributedStringValue:displayString];
    
    switch (item.playlistType)
    {
        case kPlaylistTypeLovedSongs: {
            if(isSelected)
                [cell setImage:[NSImage imageNamed:@"Playlist_Remote_Selected"]];
            else
                [cell setImage:[NSImage imageNamed:@"Playlist_Remote"]];
            
            break;
        }
            
        case kPlaylistTypeFriendsLovedSongs: {
            if(isSelected)
                [cell setImage:[NSImage imageNamed:@"Playlist_Friends_Selected"]];
            else
                [cell setImage:[NSImage imageNamed:@"Playlist_Friends"]];
            
            break;
        }
            
        case kPlaylistTypeDefault:
        case kPlaylistTypePurchasedMusic: {
            if(isSelected)
                [cell setImage:[NSImage imageNamed:@"Playlist_Regular_Selected"]];
            else
                [cell setImage:[NSImage imageNamed:@"Playlist_Regular"]];
            
            break;
        }
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Unrecognized playlist type."];
    }
    
    [cell setImageInset:5.0];
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
#pragma mark Child Levels

- (BOOL)isChildLevelAvailableForItem:(Playlist *)item
{
    return YES;
}

- (RKBrowserLevel *)childBrowserLevelForItem:(Playlist *)item
{
    if(item == mFriendActivityLevelPlaylist)
    {
        if(!mFriendActivityLevel)
            mFriendActivityLevel = [FriendActivityBrowserLevel new];
        
        return mFriendActivityLevel;
    }
    
    SongsBrowserLevel *songBrowserLevel = [SongsBrowserLevel new];
    songBrowserLevel.parent = item;
    
    if(item.playlistType == kPlaylistTypeLovedSongs)
        songBrowserLevel.showsArtwork = YES;
    
    return songBrowserLevel;
}

#pragma mark -
#pragma mark Pasteboard

- (BOOL)writeLevelItems:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard
{
    [pasteboard clearContents];
    [pasteboard writeObjects:[rows valueForKeyPath:@"@unionOfArrays.songs"]];
    
    return YES;
}

@end