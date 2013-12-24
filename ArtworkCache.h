//
//  ArtworkCache.h
//  Pinna
//
//  Created by Peter MacWhinnie on 1/24/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Album, Song;

///This class is responsible for managing the artwork tiles used by Player.
@interface ArtworkCache : NSObject
{
	NSCache *mImageCache;
	
	NSOperationQueue *mCachingQueue;
}

///Returns the shared artwork cache, creating it if it doesn't exist.
+ (ArtworkCache *)sharedArtworkCache;

///Erase the artwork cache.
- (void)deleteCachedArtwork;

#pragma mark - Accessing Artwork

///Returns YES if the receiver has artwork for a specified album in its cache; NO otherwise.
- (BOOL)hasArtworkForAlbum:(Album *)album;

///Asynchronously cache the artwork for an album.
- (void)cacheArtworkForAlbums:(NSArray *)albums completionHandler:(void(^)())completionHandler;

///Returns the cached artwork for a specified album.
- (NSImage *)artworkForAlbum:(Album *)album;

///Returns the cached artwork for a specified album
- (NSImage *)artworkForSong:(Song *)album;

#pragma mark - Controlling Access

///Inform the receiver that you will be accessing it extensively.
- (void)beginCacheAccess;

///Inform the receiver that you have finished accessing it extensively.
- (void)endCacheAccess;

@end
