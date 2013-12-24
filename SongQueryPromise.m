//
//  SongQueryPromise.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 10/3/12.
//
//

#import "SongQueryPromise.h"

#import "Library.h"
#import "Song.h"
#import "ExfmSession.h"

NSString *const SongQueryPromiseSongNameErrorKey = @"SongQueryPromiseSongNameErrorKey";
NSString *const SongQueryPromiseSongArtistErrorKey = @"SongQueryPromiseSongArtistErrorKey";

@implementation SongQueryPromise

#pragma mark Lifecycle

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithIdentifier:(NSString *)identifier
{
	NSParameterAssert(identifier);
	NSAssert(([identifier rangeOfString:@"$"].location != NSNotFound),
			 @"Malformed identifier %@ given", identifier);
	
    NSArray *identifierComponents = [identifier componentsSeparatedByString:@"$"];
    NSString *name = [[[identifierComponents objectAtIndex:0] stringByReplacingOccurrencesOfString:@"\\$" withString:@"$"] stringByReplacingOccurrencesOfString:@"\\," withString:@","];
    NSString *artist = [[[identifierComponents objectAtIndex:1] stringByReplacingOccurrencesOfString:@"\\$" withString:@"$"] stringByReplacingOccurrencesOfString:@"\\," withString:@","];
    
	return [self initWithName:name ?: @"" artist:artist ?: artist];
}

- (id)initWithName:(NSString *)name artist:(NSString *)artist
{
    NSParameterAssert(name);
    NSParameterAssert(artist);
    
    if((self = [super init]))
    {
        mName = [name copy];
        mArtist = [artist copy];
        
        mLibrary = [Library sharedLibrary];
    }
    
    return self;
}

#pragma mark - Properties

@synthesize name = mName;
@synthesize artist = mArtist;

#pragma mark - Execution

- (NSString *)sanitizeStringForQuery:(NSString *)string dropApostrophes:(BOOL)dropApostrophes
{
	if(!string)
		return nil;
	
	NSUInteger(^findClosingCharacterLocation)(NSString *, unichar, NSUInteger) = ^NSUInteger(NSString *haystack, unichar needle, NSUInteger index) {
		for (; index < [haystack length]; index++)
		{
			unichar possibleMatch = [haystack characterAtIndex:index];
			if(possibleMatch == needle)
				return index + 1;
		}
		
		return [haystack length];
	};
	
	NSMutableString *newString = [string mutableCopy];
	
	NSInteger indexOfOpeningParen = NSNotFound;
	while ((indexOfOpeningParen = [newString rangeOfString:@"("].location) != NSNotFound)
	{
		if(indexOfOpeningParen != 0 && [newString characterAtIndex:indexOfOpeningParen - 1] == ' ')
			indexOfOpeningParen--;
		
		NSInteger indexOfClosingParen = findClosingCharacterLocation(newString, ')', indexOfOpeningParen);
		[newString deleteCharactersInRange:NSMakeRange(indexOfOpeningParen, indexOfClosingParen - indexOfOpeningParen)];
	}
	
	NSInteger indexOfOpeningBracket = NSNotFound;
	while ((indexOfOpeningBracket = [newString rangeOfString:@"["].location) != NSNotFound)
	{
		if(indexOfOpeningBracket != 0 && [newString characterAtIndex:indexOfOpeningBracket - 1] == ' ')
			indexOfOpeningBracket--;
		
		NSInteger indexOfClosingBracket = findClosingCharacterLocation(newString, ']', indexOfOpeningBracket);
		[newString deleteCharactersInRange:NSMakeRange(indexOfOpeningBracket, indexOfClosingBracket - indexOfOpeningBracket)];
	}
	
    if(dropApostrophes)
    {
        [newString replaceOccurrencesOfString:@"'" 
                                   withString:@""
                                      options:0
                                        range:NSMakeRange(0, [newString length])];
    }
    
	return newString;
}

- (void)fire
{
	Song *possibleMatch = [[mLibrary.songs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name ==[cd] %@ && artist ==[cd] %@", mName, mArtist]] lastObject];
	if(possibleMatch)
	{
        [self accept:possibleMatch];
		
		return;
	}
	
	possibleMatch = [[mLibrary.songs filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name ==[cd] %@ && artist ==[cd] %@", [self sanitizeStringForQuery:mName dropApostrophes:NO], [self sanitizeStringForQuery:mArtist dropApostrophes:NO]]] lastObject];
	if(possibleMatch)
	{
		[self accept:possibleMatch];
		
		return;
	}
	
	NSString *query = [NSString stringWithFormat:@"%@ %@", [self sanitizeStringForQuery:mArtist dropApostrophes:YES], [self sanitizeStringForQuery:mName dropApostrophes:YES]];
	RKPromise *songSearch = [[ExfmSession defaultSession] searchSongsWithQuery:query offset:0];
	[songSearch then:^(NSDictionary *response) {
		NSArray *songs = [response objectForKey:@"songs"];
		NSDictionary *songResult = RKCollectionFindFirstMatch(songs, ^BOOL(NSDictionary *songResult) {
			NSString *title = RKFilterOutNSNull([songResult objectForKey:@"title"]);
			NSString *artist = RKFilterOutNSNull([songResult objectForKey:@"artist"]);
			return (([title caseInsensitiveCompare:mName] == NSOrderedSame || [[title lowercaseString] hasPrefix:[mName lowercaseString]]) &&
					([artist caseInsensitiveCompare:mArtist] == NSOrderedSame || [[artist lowercaseString] hasPrefix:[mArtist lowercaseString]]));
		});
		if(songResult)
		{
			Song *match = [[Song alloc] initWithTrackDictionary:songResult source:kSongSourceExfm];
			[self accept:match];
		}
		else
		{
			NSError *error = [NSError errorWithDomain:@"SongQueryPromiseErrorDomain"
												 code:-9393
											 userInfo:@{NSLocalizedDescriptionKey: @"Could not find song.",
                                                        SongQueryPromiseSongNameErrorKey: mName,
                                                        SongQueryPromiseSongArtistErrorKey: mArtist}];
			[self reject:error];
		}
	} otherwise:^(NSError *error) {
		[self reject:error];
	}];
}

@end
