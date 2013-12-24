//
//  LyricsCache.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/4/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Song;

///The LyricsCache class is responsible for managing lyrics inputted into Pinna by the user.
@interface LyricsCache : NSObject
{
	NSCache *mLyricsCache;
	
	NSOperationQueue *mCachingQueue;
}

#pragma mark Lifecycle

///Returns the shared lyrics cache object, creating it if it doesn't exist.
+ (LyricsCache *)sharedLyricsCache;

///Causes the receiver to clear its lyrics cache.
- (void)deleteLyricsCache;

#pragma mark - Accessing the Cache

///Returns a BOOL indicating whether or not the receiver has cached lyrics for a song.
- (BOOL)hasLyricsForSong:(Song *)song;

///Asynchronously cache lyrics for a specified (required) song.
- (void)cacheLyrics:(NSString *)lyrics forSong:(Song *)song;

///Returns the cached lyrics for a song, if any exist.
- (NSString *)lyricsForSong:(Song *)song;

@end
