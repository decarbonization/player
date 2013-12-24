//
//  ArtworkCache.m
//  Pinna
//
//  Created by Peter MacWhinnie on 1/24/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "ArtworkCache.h"
#import <QuickLook/QuickLook.h>

#import "Library.h"
#import "Artist.h"
#import "Album.h"
#import "Song.h"

#import "PlayerApplication.h"

static NSUInteger kHighCacheLimit = 50;
static NSUInteger kLowCacheLimit = 5;

///Returns a data representation for an image of a specified type.
///
/// \param  image   The image to return a representation for. Required.
/// \param  type    The type of data to return.
///
/// \result An NSData object matching the `type`.
///
///This function is significantly slower for non-bitmap images as a conversion operation is required.
static NSData *xNSImageGetRepresentation(NSImage *image, NSBitmapImageFileType type)
{
	NSCParameterAssert(image);
	
	//We attempt to get an existing image representation from the image.
	NSBitmapImageRep *imageRep = nil;
	for (id representation in [image representations])
	{
		if([representation isKindOfClass:[NSBitmapImageRep class]])
		{
			imageRep = representation;
			break;
		}
	}
	
	//If there is no existing image representation, we just make a new
	//representation in the usual, incredibly inefficient manner.
	if(!imageRep)
		imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
	
	return [imageRep representationUsingType:type properties:nil];
}

#pragma mark -

@implementation ArtworkCache

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

- (NSString *)artworkCacheDirectoryPath
{
	return [[self applicationCacheDirectoryPath] stringByAppendingPathComponent:@"Artwork"];
}

#pragma mark - Lifecycle

+ (ArtworkCache *)sharedArtworkCache
{
	static ArtworkCache *sharedCache = nil;
	static dispatch_once_t predicate = 0;
	dispatch_once(&predicate, ^{
		sharedCache = [ArtworkCache new];
	});
	
	return sharedCache;
}

- (id)init
{
	if((self = [super init]))
	{
		NSError *error = nil;
		NSString *artworkCachePath = [self artworkCacheDirectoryPath];
		
		if(![[NSFileManager defaultManager] fileExistsAtPath:artworkCachePath])
		{
			NSAssert([[NSFileManager defaultManager] createDirectoryAtPath:artworkCachePath withIntermediateDirectories:YES attributes:nil error:&error],
					 @"Could not create artwork cache directory (%@). Error %@.", artworkCachePath, [error localizedDescription]);
		}
		
		mCachingQueue = [NSOperationQueue new];
		[mCachingQueue setName:@"com.roundabout.pinna.ArtworkCache.mCachingQueue"];
		[mCachingQueue setMaxConcurrentOperationCount:1];
		[NSApp addImportantQueue:mCachingQueue];
		
		mImageCache = [NSCache new];
		[mImageCache setCountLimit:kLowCacheLimit];
	}
	
	return self;
}

#pragma mark -

- (void)deleteCachedArtwork
{
	[mCachingQueue addOperationWithBlock:^{
		[mImageCache removeAllObjects];
		
		NSError *error = nil;
		NSString *artworkCachePath = [self artworkCacheDirectoryPath];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:artworkCachePath])
		{
			if(![[NSFileManager defaultManager] removeItemAtPath:artworkCachePath error:&error])
			{
				NSLog(@"Could not delete artwork cache folder.");
				return;
			}
			
			if(![[NSFileManager defaultManager] createDirectoryAtPath:artworkCachePath withIntermediateDirectories:YES attributes:nil error:&error])
			{
				[NSException raise:NSInternalInconsistencyException format:@"Could not create artwork cache directory (%@). Error %@.", artworkCachePath, [error localizedDescription]];
			}
		}
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[[Library sharedLibrary] willChangeValueForKey:@"albums"];
			[[Library sharedLibrary] didChangeValueForKey:@"albums"];
		}];
	}];
}

#pragma mark - Accessing Artwork

- (NSString *)imageNameForAlbum:(Album *)album
{
	if(!album)
		return nil;
	
	return [RKGenerateIdentifierForStrings(@[album.artist.name, album.name]) stringByAppendingPathExtension:@"png"];
}

- (NSString *)imageLocationForAlbum:(Album *)album
{
	NSString *imageName = [self imageNameForAlbum:album];
	if(!imageName)
		return nil;
	
	return [[self artworkCacheDirectoryPath] stringByAppendingPathComponent:imageName];
}

- (NSString *)imageNameForSong:(Song *)song
{
	if(!song)
		return nil;
	
	return [RKGenerateIdentifierForStrings(@[song.artist ?: @"", song.album ?: @""]) stringByAppendingPathExtension:@"png"];
}

- (NSString *)imageLocationForSong:(Song *)song
{
	NSString *imageName = [self imageNameForSong:song];
	if(!imageName)
		return nil;
	
	return [[self artworkCacheDirectoryPath] stringByAppendingPathComponent:imageName];
}

#pragma mark -

- (NSImage *)artworkImageForAlbum:(Album *)album
{
	Song *songChoice = nil;
	for (Song *albumSong in album.songs)
	{
		if(![albumSong.location isFileURL])
			continue;
		
		songChoice = albumSong; 
	}
	
	if(!songChoice)
	{
		songChoice = [album.songs lastObject];
		NSDictionary *remoteArtworkLocation = songChoice.remoteArtworkLocations;
		if(![remoteArtworkLocation objectForKey:@"small"])
			return nil;
		
		return [[NSImage alloc] initWithContentsOfURL:[remoteArtworkLocation objectForKey:@"small"]];
	}
	
	CGImageRef thumbnail = QLThumbnailImageCreate(kCFAllocatorDefault, 
												  (__bridge CFURLRef)(songChoice.location), 
												  CGSizeMake(512.0, 512.0), 
												  NULL);
	if(thumbnail)
	{
		NSBitmapImageRep *artworkImageRep = [[NSBitmapImageRep alloc] initWithCGImage:thumbnail];
		NSImage *artworkImage = [[NSImage alloc] initWithSize:[artworkImageRep size]];
		[artworkImage addRepresentation:artworkImageRep];
		CGImageRelease(thumbnail);
		return artworkImage;
	}
	
	return nil;
}

- (NSImage *)thumbnailForImage:(NSImage *)sourceImage
{
	NSImage *thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(64.0, 64.0)];
	[thumbnail lockFocus];
	{
		[sourceImage setFlipped:NO];
		[sourceImage drawInRect:NSMakeRect(0.0, 0.0, 64.0, 64.0) 
					   fromRect:NSZeroRect 
					  operation:NSCompositeSourceOver 
					   fraction:1.0 
				 respectFlipped:YES 
						  hints:nil];
	}
	[thumbnail unlockFocus];
	
	return thumbnail;
}

#pragma mark -

- (BOOL)hasArtworkForAlbum:(Album *)album
{
	NSString *imageLocationForAlbum = [self imageLocationForAlbum:album];
	return (imageLocationForAlbum && [[NSFileManager defaultManager] fileExistsAtPath:imageLocationForAlbum]);
}

- (void)cacheArtworkForAlbums:(NSArray *)albums completionHandler:(void(^)())completionHandler
{
	completionHandler = [completionHandler copy];
	
	__block ArtworkCache *me = self;
	[mCachingQueue addOperationWithBlock:^{
		NSError *error = nil;
		NSMutableSet *currentArtwork = [NSMutableSet set];
		
		for (Album *album in albums)
		{
			if([NSApp isWaitingForImportantQueuesToFinish])
				return;
			
			NSString *imageLocationForAlbum = [me imageLocationForAlbum:album];
			if(imageLocationForAlbum && [[NSFileManager defaultManager] fileExistsAtPath:imageLocationForAlbum])
			{
				[currentArtwork addObject:[me imageNameForAlbum:album]];
				continue;
			}
			
			NSImage *fullArtwork = [me artworkImageForAlbum:album];
			if(!fullArtwork)
				continue;
			
			[currentArtwork addObject:[me imageNameForAlbum:album]];
			
			NSImage *thumbnail = [me thumbnailForImage:fullArtwork];
			NSData *imageData = xNSImageGetRepresentation(thumbnail, NSPNGFileType);
			if(![imageData writeToFile:[me imageLocationForAlbum:album] options:NSAtomicWrite error:&error])
			{
				NSLog(@"*** Could not write out artwork cache for album %@ ***", album);
				continue;
			}
		}
		
		if([NSApp isWaitingForImportantQueuesToFinish])
			return;
		
		NSString *artworkCacheDirectoryPath = [me artworkCacheDirectoryPath];
		NSArray *storedArtwork = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:artworkCacheDirectoryPath error:&error];
		if(storedArtwork)
		{
			for (NSString *storedArtworkName in storedArtwork)
			{
				if([NSApp isWaitingForImportantQueuesToFinish])
					return;
				
				if(![currentArtwork member:storedArtworkName])
				{
					NSString *artworkPath = [artworkCacheDirectoryPath stringByAppendingPathComponent:storedArtworkName];
					if(![[NSFileManager defaultManager] removeItemAtPath:artworkPath error:&error])
					{
						NSLog(@"*** Could not remove stored artwork %@ ***", artworkPath);
					}
				}
			}
		}
		else
		{
			NSLog(@"*** Could not look up artwork on mass storage device. ***");
		}
		
		if(completionHandler)
			[[NSOperationQueue mainQueue] addOperationWithBlock:completionHandler];
	}];
}

- (NSImage *)artworkForAlbum:(Album *)album
{
	NSString *imageLocationForAlbum = [self imageLocationForAlbum:album];
	NSImage *image = [mImageCache objectForKey:imageLocationForAlbum];
	if(!image)
	{
		image = [[NSImage alloc] initWithContentsOfFile:imageLocationForAlbum];
		if(image)
			[mImageCache setObject:image forKey:imageLocationForAlbum];
	}
	
	return image;
}

- (NSImage *)artworkForSong:(Song *)album
{
	NSString *imageLocationForSong = [self imageLocationForSong:album];
	NSImage *image = [mImageCache objectForKey:imageLocationForSong];
	if(!image)
	{
		image = [[NSImage alloc] initWithContentsOfFile:imageLocationForSong];
		if(image)
			[mImageCache setObject:image forKey:imageLocationForSong];
	}
	
	return image;
}

#pragma mark - Controlling Access

- (void)beginCacheAccess
{
	[mImageCache setCountLimit:kHighCacheLimit];
}

- (void)endCacheAccess
{
	[mImageCache setCountLimit:kLowCacheLimit];
}

@end
