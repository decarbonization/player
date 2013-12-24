//
//  Artist.h
//  Pinna
//
//  Created by Peter MacWhinnie on 11/17/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Album;

@interface Artist : NSObject
{
	NSString *mName;
	NSMutableArray *mAlbums;
	BOOL mIsCompilationContainer;
}

///Initialize a new artist with a specified name.
- (id)initWithName:(NSString *)name isCompilationContainer:(BOOL)isCompilationContainer;

#pragma mark - Properties

///The name of the artist.
///
///The value of this property is not fit for display if `isCompilationContainer` is YES.
@property (readonly) NSString *name;

///The interface-ready name of the artist.
///
///This should be preferred over `name`.
@property (readonly) NSString *displayName;

///The albums of the artist. Friend-objects may mutate this value through `-mutableArrayValueForKeyPath:`.
@property (readonly) NSArray *albums;

///The songs of the artist. Readonly.
@property (readonly) NSArray *songs;

///Whether or not the artist is a compilation container.
@property (readonly) BOOL isCompilationContainer;

#pragma mark -

///Returns the first known album with a specified name.
- (Album *)albumWithName:(NSString *)name;

#pragma mark - Identity

///Returns a predicate suitable for a search UI displaying an array of artists.
+ (NSPredicate *)searchPredicateForQueryString:(NSString *)queryString;

@end
