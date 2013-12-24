//
//  ContextualMenuGenerator.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 8/22/12.
//
//

#import "MenuGenerator.h"

#import "Library.h"
#import "Song.h"
#import "Artist.h"
#import "Album.h"
#import "Playlist.h"

#import "AppDelegate.h"
#import "MainWindow.h"

@interface MenuGenerator () <NSSharingServiceDelegate>

@end

@implementation MenuGenerator

#pragma mark Lifecycle

+ (MenuGenerator *)sharedGenerator
{
	static MenuGenerator *sharedGenerator = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedGenerator = [MenuGenerator new];
	});
	
	return sharedGenerator;
}

- (id)init
{
	if((self = [super init]))
	{
		library = [Library sharedLibrary];
	}
	
	return self;
}

#pragma mark - Actions

#pragma mark • Local

- (void)showInFinder:(NSMenuItem *)sender
{
	NSArray *songs = [sender representedObject];
	NSArray *locations = RKCollectionMapToArray(songs, ^NSURL *(Song *song) { return song.location; });
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:locations];
}

#pragma mark - Generating Menus

#pragma mark • Deriving Items

- (NSArray *)songsFromItems:(NSArray *)items
{
	NSMutableArray *songs = [NSMutableArray array];
	for (id item in items)
	{
		if([item isKindOfClass:[Song class]])
		{
			[songs addObject:item];
		}
		else if([item respondsToSelector:@selector(songs)])
		{
			[songs addObjectsFromArray:[item songs]];
		}
	}
	
	return songs;
}

- (void)divideSongs:(NSArray *)source intoLocal:(NSArray **)outLocal andExFM:(NSArray **)outExFM
{
	NSParameterAssert(source);
	
	NSMutableArray *localSongs = [NSMutableArray array];
	NSMutableArray *exFMSongs = [NSMutableArray array];
	
	for (Song *song in source)
	{
		switch (song.songSource)
		{
			case kSongSourceITunes:
			case kSongSourceLocalFile:
				[localSongs addObject:song];
				
				if([library alternateSourceIdentifierForSong:song])
					[exFMSongs addObject:song];
				
				break;
				
			case kSongSourceExfm:
				[exFMSongs addObject:song];
				break;
				
			default:
				[NSException raise:NSInternalInconsistencyException format:@"Unknown song source %ld", song.songSource];
				break;
		}
	}
	
	if(outLocal) *outLocal = localSongs;
	if(outExFM) *outExFM = exFMSongs;
}

#pragma mark - • Generating Menu Items

- (NSString *)correctPluralizationOfString:(NSString *)string forCount:(NSUInteger)count
{
	NSMutableString *correctedString = [string mutableCopy];
	if(count == 1)
	{
		[correctedString replaceOccurrencesOfString:@"{s}"
										 withString:@""
											options:0
											  range:NSMakeRange(0, [correctedString length])];
		[correctedString replaceOccurrencesOfString:@"{es}"
										 withString:@""
											options:0
											  range:NSMakeRange(0, [correctedString length])];
	}
	else
	{
		[correctedString replaceOccurrencesOfString:@"{s}"
										 withString:@"s"
											options:0
											  range:NSMakeRange(0, [correctedString length])];
		[correctedString replaceOccurrencesOfString:@"{es}"
										 withString:@"es"
											options:0
											  range:NSMakeRange(0, [correctedString length])];
	}
	
	return correctedString;
}

- (void)addItemsForLocalSongs:(NSArray *)localSongs toMenu:(NSMenu *)menu
{
	if([localSongs count] == 0)
		return;
	
	//- Show in Finder
	NSMenuItem *showInFinderItem = [menu addItemWithTitle:@"Show in Finder" action:@selector(showInFinder:) keyEquivalent:@""];
	[showInFinderItem setTarget:self];
	[showInFinderItem setRepresentedObject:localSongs];
}

- (void)addItemsForAllSongs:(NSArray *)songs toMenu:(NSMenu *)menu
{
	if([songs count] == 0)
		return;
	
    /* This is where actions related to exfm once lived. */
}

#pragma mark -

- (NSMenu *)contextualMenuForLibraryItems:(NSArray *)items
{
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	
	NSArray *allSongs = [self songsFromItems:items];
	NSArray *localSongs = nil;
	NSArray *exFMSongs = nil;
	[self divideSongs:allSongs intoLocal:&localSongs andExFM:&exFMSongs];
	
	[self addItemsForLocalSongs:localSongs toMenu:menu];
	
	if([localSongs count] > 0)
		[menu addItem:[NSMenuItem separatorItem]];
	
	[self addItemsForAllSongs:allSongs toMenu:menu];
	
	return menu;
}

@end
