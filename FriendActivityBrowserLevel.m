//
//  FriendActivityBrowserLevel.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 9/29/12.
//
//

#import "FriendActivityBrowserLevel.h"

#import "AppDelegate.h"
#import "RKBrowserView.h"
#import "PreferencesWindow.h"
#import "MenuGenerator.h"

#import "Library.h"
#import "ExfmSession.h"

#import "Song.h"

static NSUInteger kHighCacheLimit = 50;
static NSUInteger kLowCacheLimit = 5;
static NSUInteger kNumberOfConcurrentDownloads = 5;

@implementation FriendActivityBrowserLevel

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
	if((self = [super init]))
	{
		mLibrary = [Library sharedLibrary];
        mExfmSession = [ExfmSession defaultSession];
		mCachedActors = [NSArray array];
		mCachedSongs = [NSArray array];
		
		mArtworkCache = [NSCache new];
		[mArtworkCache setName:@"com.roundabout.pinna.ExploreBrowserLevel.mArtworkCache"];
		[mArtworkCache setCountLimit:kLowCacheLimit];
		
		mArtworkBeingDownloaded = [NSMutableSet set];
		
		mArtworkDownloadQueue = [NSOperationQueue new];
		[mArtworkDownloadQueue setMaxConcurrentOperationCount:kNumberOfConcurrentDownloads];
		[mArtworkDownloadQueue setName:@"com.roundabout.pinna.ExploreBrowserLevel.mArtworkDownloadQueue"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(exfmSessionUpdatedCachedLovedSongsOfFriends:)
													 name:ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification
												   object:[ExfmSession defaultSession]];
	}
	
	return self;
}

#pragma mark -

- (NSArray *)songsFromExFMData:(NSArray *)exFMSongs
{
	NSArray *allSongs = [Library sharedLibrary].songs;
	return RKCollectionMapToArray(exFMSongs, ^id(NSDictionary *track) {
		Song *song = [[Song alloc] initWithTrackDictionary:track source:kSongSourceExfm];
		Song *possibleLocalEquivalentSong = BestMatchForSongInArray(song, allSongs);
		if(possibleLocalEquivalentSong)
		{
			if(possibleLocalEquivalentSong.sourceIdentifier && song.sourceIdentifier)
				[mLibrary registerExternalAlternateIdentifier:song.sourceIdentifier forSong:possibleLocalEquivalentSong];
			
			return possibleLocalEquivalentSong;
		}
		
		return song;
	});
}

- (void)updateSongs
{
    [self willChangeValueForKey:@"contents"];
    
    NSDictionary *friendLoveActivity = [ExfmSession defaultSession].cachedFriendLoveActivity;
    [self willChangeValueForKey:@"contents"];
    mCachedActors = [friendLoveActivity valueForKeyPath:@"activities.actor"];
    mCachedSongs = [self songsFromExFMData:[friendLoveActivity valueForKeyPath:@"activities.object"]];
    [self didChangeValueForKey:@"contents"];
}

#pragma mark - Providing Content

- (NSString *)title
{
	return @"Recently Loved by Friends";
}

+ (NSSet *)keyPathsForValuesAffectingContents
{
	return [NSSet setWithObjects:@"mExfmSession.isAuthorized", nil];
}

- (NSArray *)contents
{
	return mCachedSongs;
}

#pragma mark -

- (void)exfmSessionUpdatedCachedLovedSongsOfFriends:(NSNotification *)notification
{
	[self updateSongs];
}

#pragma mark - Display

- (void)levelWillBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	[super levelWillBecomeVisibleInBrowser:browserView];
	
    [self updateSongs];
    [mArtworkCache setCountLimit:kHighCacheLimit];
}

- (void)levelWillBeRemovedFromBrowser:(RKBrowserView *)browserView
{
    [super levelWillBeRemovedFromBrowser:browserView];
    
    [ExfmSession defaultSession].numberOfNewFriendLoveActivities = 0;
    
    //This ensures the Playlists level updates.
    [[NSNotificationCenter defaultCenter] postNotificationName:ExfmSessionUpdatedCachedLovedSongsOfFriendsNotification
                                                        object:[ExfmSession defaultSession]];
}

- (void)levelWasRemovedFromBrowser:(RKBrowserView *)browserView
{
	[super levelWasRemovedFromBrowser:browserView];
	
    [mArtworkCache setCountLimit:kLowCacheLimit];

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
	NSDictionary *actor = [mCachedActors objectAtIndex:index];
	NSString *actorName = RKFilterOutNSNull([actor objectForKey:@"display_name"]) ?: @"Unknown";
	NSString *string = [NSString stringWithFormat:@"%@\n%@ | Loved by %@", item.name, item.artist, actorName];
	
	NSAttributedString *displayString = [RKBrowserLevel formatBrowserTextForDisplay:string isSelected:isSelected dividerString:@"\n"];
	[cell setAttributedStringValue:displayString];
	
	NSImage *artworkImage = [self artworkImageForSong:item];
    [artworkImage setSize:NSMakeSize(32.0, 32.0)];
    [cell setImage:artworkImage];
	[cell setStylizesImage:YES];
}

#pragma mark - Hover Buttons

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

#pragma mark - Child Levels

- (BOOL)isChildLevelAvailableForItem:(Song *)item
{
	return NO;
}

#pragma mark - Pasteboard

- (BOOL)writeLevelItems:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard
{
	[pasteboard clearContents];
	[pasteboard writeObjects:rows];
	
	return YES;
}

@end
