//
//  LyricsCache.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/4/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "LyricsCache.h"

#import "Song.h"

#import "PlayerApplication.h"

@implementation LyricsCache

#pragma mark Paths

- (NSString *)applicationCacheDirectoryPath
{
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	if(!cachesPath)
	{
		cachesPath = NSTemporaryDirectory();
		NSLog(@"Could not find caches directory. Huh?");
	}
	
	return [cachesPath stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
}

- (NSString *)lyricsCacheDirectoryPath
{
	return [[self applicationCacheDirectoryPath] stringByAppendingPathComponent:@"Lyrics"];
}

#pragma mark - Lifecycle

+ (LyricsCache *)sharedLyricsCache
{
	static LyricsCache *sharedLyricsCache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedLyricsCache = [LyricsCache new];
	});
	
	return sharedLyricsCache;
}

- (id)init
{
	if((self = [super init]))
	{
		NSError *error = nil;
		NSString *lyricsCachePath = [self lyricsCacheDirectoryPath];
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:lyricsCachePath])
		{
			NSAssert([[NSFileManager defaultManager] createDirectoryAtPath:lyricsCachePath withIntermediateDirectories:YES attributes:nil error:&error],
					 @"Could not create lyrics cache directory (%@). Error %@.", lyricsCachePath, [error localizedDescription]);
		}
		
		mCachingQueue = [NSOperationQueue new];
		[mCachingQueue setName:@"com.roundabout.pinna.LyricsCache.mCachingQueue"];
		[mCachingQueue setMaxConcurrentOperationCount:1];
		[NSApp addImportantQueue:mCachingQueue];
		
		mLyricsCache = [NSCache new];
		[mLyricsCache setCountLimit:5];
	}
	
	return self;
}

- (void)deleteLyricsCache
{
	[mCachingQueue addOperationWithBlock:^{
		NSError *error = nil;
		NSString *lyricsCachePath = [self lyricsCacheDirectoryPath];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:lyricsCachePath])
		{
			if(![[NSFileManager defaultManager] removeItemAtPath:lyricsCachePath error:&error])
			{
				NSLog(@"Could not delete lyrics cache folder.");
				return;
			}
			
			if(![[NSFileManager defaultManager] createDirectoryAtPath:lyricsCachePath withIntermediateDirectories:YES attributes:nil error:&error])
			{
				[NSException raise:NSInternalInconsistencyException format:@"Could not create lyrics cache directory (%@). Error %@.", lyricsCachePath, [error localizedDescription]];
			}
		}
	}];
}

#pragma mark - Accessing Cache

- (NSString *)locationOfLyricsFileForSong:(Song *)song
{
	NSString *lyricsCachePath = [self lyricsCacheDirectoryPath];
	return [lyricsCachePath stringByAppendingPathComponent:[RKStringGetMD5Hash(song.uniqueIdentifier) stringByAppendingPathExtension:@"txt"]];
}

#pragma mark -

- (BOOL)hasLyricsForSong:(Song *)song
{
	NSString *textLocationForSong = [self locationOfLyricsFileForSong:song];
	return (textLocationForSong && [[NSFileManager defaultManager] fileExistsAtPath:textLocationForSong]);
}

- (void)cacheLyrics:(NSString *)lyrics forSong:(Song *)song
{
	NSParameterAssert(song);
	
	[mCachingQueue addOperationWithBlock:^{
		NSError *error = nil;
		NSString *textLocationForSong = [self locationOfLyricsFileForSong:song];
		if(lyrics)
		{
			if([lyrics writeToFile:textLocationForSong atomically:YES encoding:NSUTF8StringEncoding error:&error])
			{
				[mLyricsCache setObject:lyrics forKey:song.uniqueIdentifier];
			}
			else
			{
				NSLog(@"Could not write out lyrics for song %@, error %@", song, error);
			}
		}
		else
		{
			[mLyricsCache removeObjectForKey:song.uniqueIdentifier];
			
			if(![[NSFileManager defaultManager] removeItemAtPath:textLocationForSong error:&error])
			{
				NSLog(@"Could not remove lyrics for song %@, error %@", song, error);
			}
		}
	}];
}

- (NSString *)lyricsForSong:(Song *)song
{
	NSString *lyrics = [mLyricsCache objectForKey:song.uniqueIdentifier];
	if(lyrics)
		return lyrics;
	
	if(![self hasLyricsForSong:song])
		return nil;
	
	NSString *textLocationForSong = [self locationOfLyricsFileForSong:song];
	if(textLocationForSong)
	{
		NSError *error = nil;
		lyrics = [NSString stringWithContentsOfFile:textLocationForSong encoding:NSUTF8StringEncoding error:&error];
		if(lyrics)
		{
			[mLyricsCache setObject:lyrics forKey:song.sourceIdentifier];
		}
		else
		{
			NSLog(@"Could not load lyrics for song %@, error %@", song, error);
		}
	}
	
	return lyrics;
}

@end
