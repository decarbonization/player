//
//  Playlist.m
//  Pinna
//
//  Created by Peter MacWhinnie on 12/4/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "Playlist.h"
#import "Song.h"

@implementation Playlist

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithName:(NSString *)name songs:(NSArray *)songs playlistType:(PlaylistType)playlistType
{
	if((self = [super init]))
	{
		mName = [name copy];
		mSongs = [songs copy];
		mPlaylistType = playlistType;
	}
	
	return self;
}

#pragma mark - Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[Playlist class]])
	{
		return [mName isEqualTo:[object name]];
	}
	
	return NO;
}

- (BOOL)isEqual:(id)object
{
	return [self isEqualTo:object];
}

- (NSUInteger)hash
{
	return (5 + [mName hash]) << 2;
}

+ (NSPredicate *)searchPredicateForQueryString:(NSString *)queryString
{
	NSParameterAssert(queryString);
	
	NSMutableString *sanitizedQueryString = [queryString mutableCopy];
	[sanitizedQueryString replaceOccurrencesOfString:@"+" 
										  withString:@"" 
											 options:0 
											   range:NSMakeRange(0, [sanitizedQueryString length])];
	[sanitizedQueryString replaceOccurrencesOfString:@"," 
										  withString:@"" 
											 options:0 
											   range:NSMakeRange(0, [sanitizedQueryString length])];
	
	NSArray *searchQueryParts = [sanitizedQueryString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	return [NSPredicate predicateWithBlock:^(Playlist *playlist, NSDictionary *bindings) {
		return RKCollectionDoAllValuesMatch(searchQueryParts, ^BOOL(NSString *queryPart) {
			if([queryPart length] == 0)
				return YES;
			
			return playlist.name && [playlist.name rangeOfString:queryPart 
														 options:(NSCaseInsensitiveSearch | 
																  NSDiacriticInsensitiveSearch | 
																  NSWidthInsensitiveSearch)].location != NSNotFound;
		});
	}];
}

#pragma mark - Properties

@synthesize name = mName;
@synthesize songs = mSongs;
@synthesize playlistType = mPlaylistType;

@end
