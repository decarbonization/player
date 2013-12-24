//
//  Album.h
//  Pinna
//
//  Created by Peter MacWhinnie on 11/17/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Artist;

@interface Album : NSObject
{
	NSString *mName;
	Artist *mArtist;
	NSMutableArray *mSongs;
	BOOL mIsCompilation;
}

///Initialize an album with a specified name, inserting it into a specified artist.
- (id)initWithName:(NSString *)name insertIntoArtist:(Artist *)artist isCompilation:(BOOL)isCompilation;

#pragma mark - Properties

///The name of the album.
@property (readonly) NSString *name;

///The artist the album is by.
@property (readonly) Artist *artist;

///Whether or not the album is a compilation.
@property (readonly) BOOL isCompilation;

#pragma mark -

///The songs of the album. Friend-objects may mutate this value through `-mutableArrayValueForKeyPath:`.
@property (readonly) NSArray *songs;

#pragma mark - Identity

///Returns a predicate suitable for a search UI displaying an array of albums.
+ (NSPredicate *)searchPredicateForQueryString:(NSString *)queryString;

@end
