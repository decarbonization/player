//
//  Artist.m
//  Pinna
//
//  Created by Peter MacWhinnie on 11/17/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "Artist.h"
#import "Album.h"
#import "Library.h"

@implementation Artist

- (id)initWithName:(NSString *)name isCompilationContainer:(BOOL)isCompilationContainer
{
	if((self = [super init]))
	{
		mName = [name copy];
		mAlbums = [NSMutableArray new];
		mIsCompilationContainer = isCompilationContainer;
	}
	
	return self;
}

- (id)init
{
	return [self initWithName:@"" isCompilationContainer:NO];
}

#pragma mark - Identity

- (BOOL)isEqualTo:(id)object
{
	if([object isKindOfClass:[Artist class]])
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
	return (7 + [mName hash]) << 2;
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
	
	return [NSPredicate predicateWithBlock:^(Artist *artist, NSDictionary *bindings) {
		return RKCollectionDoAllValuesMatch(searchQueryParts, ^BOOL(NSString *queryPart) {
			if([queryPart length] == 0)
				return YES;
			
			return artist.name && [artist.name rangeOfString:queryPart 
													 options:(NSCaseInsensitiveSearch | 
															  NSDiacriticInsensitiveSearch | 
															  NSWidthInsensitiveSearch)].location != NSNotFound;
		});
	}];
}

#pragma mark - Properties

@synthesize name = mName;

- (NSString *)displayName
{
	if(mIsCompilationContainer)
		return @"Various Artists";
	
	return mName;
}

@synthesize isCompilationContainer = mIsCompilationContainer;

#pragma mark -

- (void)insertAlbums:(NSArray *)albums atIndexes:(NSIndexSet *)indexes
{
	@synchronized(mAlbums)
	{
		[mAlbums insertObjects:albums atIndexes:indexes];
	}
}

- (void)removeAlbumsAtIndexes:(NSIndexSet *)indexes
{
	@synchronized(mAlbums)
	{
		[mAlbums removeObjectsAtIndexes:indexes];
	}
}

- (void)replaceAlbumsAtIndexes:(NSIndexSet *)indexes withAlbums:(NSArray *)albums
{
	@synchronized(mAlbums)
	{
		[mAlbums replaceObjectsAtIndexes:indexes withObjects:albums];
	}
}

- (void)setAlbums:(NSArray *)albums
{
	@synchronized(mAlbums)
	{
		[mAlbums setArray:albums];
	}
}

- (NSArray *)albums
{
	@synchronized(mAlbums)
	{
		return [mAlbums copy];
	}
}

#pragma mark -

- (Album *)albumWithName:(NSString *)name
{
	@synchronized(mAlbums)
	{
		for (Album *album in mAlbums)
		{
			if([album.name isEqualToString:name])
				return album;
		}
	}
	
	return nil;
}

#pragma mark -

- (NSArray *)songs
{
	NSArray *unsortedSongs = [self valueForKeyPath:@"albums.@unionOfArrays.songs"];
	return [unsortedSongs sortedArrayUsingDescriptors:kSongSortDescriptors];
}

@end
