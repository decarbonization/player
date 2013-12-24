//
//  Album.m
//  Pinna
//
//  Created by Peter MacWhinnie on 11/17/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "Album.h"
#import "Artist.h"
#import "Library.h"

@implementation Album

- (id)initWithName:(NSString *)name insertIntoArtist:(Artist *)artist isCompilation:(BOOL)isCompilation
{
	if((self = [super init]))
	{
		mName = [name copy];
		mArtist = artist;
		mSongs = [NSMutableArray new];
		mIsCompilation = isCompilation;
		
		[[artist mutableArrayValueForKey:@"albums"] addObject:self];
	}
	
	return self;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

#pragma mark - Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[Album class]])
	{
		return [mArtist isEqualTo:[object artist]] && [mName isEqualTo:[object name]];
	}
	
	return NO;
}

- (BOOL)isEqual:(id)object
{
	return [self isEqualTo:object];
}

- (NSUInteger)hash
{
	return (6 + [mName hash]) << 2;
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
	
	return [NSPredicate predicateWithBlock:^(Album *album, NSDictionary *bindings) {
		return RKCollectionDoAllValuesMatch(searchQueryParts, ^BOOL(NSString *queryPart) {
			if([queryPart length] == 0)
				return YES;
			
			BOOL(^doesMatchSearchStringPart)(NSString *) = ^BOOL(NSString *fieldValue) {
				return fieldValue && [fieldValue rangeOfString:queryPart 
													   options:(NSCaseInsensitiveSearch | 
																NSDiacriticInsensitiveSearch | 
																NSWidthInsensitiveSearch)].location != NSNotFound;
			};
			
			return (doesMatchSearchStringPart(album.name) ||
					doesMatchSearchStringPart(album.artist.name));
		});
	}];
}

#pragma mark - Properties

@synthesize name = mName;
@synthesize artist = mArtist;
@synthesize isCompilation = mIsCompilation;

#pragma mark -

- (void)insertSongs:(NSArray *)songs atIndexes:(NSIndexSet *)indexes
{
	@synchronized(mSongs)
	{
		[mSongs insertObjects:songs atIndexes:indexes];
	}
}

- (void)removeSongsAtIndexes:(NSIndexSet *)indexes
{
	@synchronized(mSongs)
	{
		[mSongs removeObjectsAtIndexes:indexes];
	}
}

- (void)replaceSongsAtIndexes:(NSIndexSet *)indexes withAlbums:(NSArray *)songs
{
	@synchronized(mSongs)
	{
		[mSongs replaceObjectsAtIndexes:indexes withObjects:songs];
	}
}

- (void)setSongs:(NSArray *)songs
{
	@synchronized(mSongs)
	{
		[mSongs setArray:songs];
	}
}

- (NSArray *)songs
{
	@synchronized(mSongs)
	{
		return [mSongs sortedArrayUsingDescriptors:kSongSortDescriptors];
	}
}

@end
