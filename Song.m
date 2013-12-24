//
//  Song.m
//  Pinna
//
//  Created by Peter MacWhinnie on 9/25/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "Song.h"
#import "Library.h"
#import "RKSandboxTools.h"
#import <libKern/OSAtomic.h>

NSString *const kSongUTI = @"com.roundabout.pinna.song";
NSString *const kSongExternalSourceTrackIdentifier = @"{external}";

enum SongArchiveVersion {
	kSongArchiveVersionInitial = 0,
};

static NSString *const kSoundcloudConsumerKey = @"dbd9af04adcb11bf14c5bd9b77e32c70";

@implementation Song

#pragma mark Initialization

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithLocation:(NSURL *)location
{
	NSParameterAssert(location);
	NSAssert([location isFileURL], @"Songs can only be created with a file URL");
	
	if([[location pathExtension] isEqualToString:@"aa"])
		return nil;
	
    MDItemRef metadata = MDItemCreateWithURL(kCFAllocatorDefault, (__bridge CFURLRef)location);
	if(!metadata)
		return nil;
	
	if((self = [super init]))
	{
		mSourceIdentifier = kSongExternalSourceTrackIdentifier;
		mIsProtected = [[mLocation pathExtension] isEqualToString:@"m4p"] || [[mLocation pathExtension] isEqualToString:@"aa"]; //The best we can do here.
		
		mLocation = location;
		
		mName = (__bridge_transfer NSString *)MDItemCopyAttribute(metadata, kMDItemTitle) ?: [[mLocation lastPathComponent] stringByDeletingPathExtension];
        
		mArtist = [(__bridge_transfer NSArray *)MDItemCopyAttribute(metadata, kMDItemAuthors) componentsJoinedByString:@" "] ?: kArtistPlaceholderName;
		mAlbumArtist =  mArtist;
		mAlbum = (__bridge_transfer NSString *)MDItemCopyAttribute(metadata, kMDItemAlbum) ?: kAlbumPlaceholderName;
		if([mAlbum length] == 0)
			mAlbum = kAlbumPlaceholderName;
		
		mGenre = (__bridge_transfer NSString *)MDItemCopyAttribute(metadata, kMDItemGenre);
		mTrackNumber = [(__bridge_transfer NSNumber *)MDItemCopyAttribute(metadata, kMDItemAudioTrackNumber) integerValue];
		
		mDuration = [(__bridge_transfer NSNumber *)MDItemCopyAttribute(metadata, kMDItemDurationSeconds) doubleValue];
		
		mSongSource = kSongSourceLocalFile;
	}
    
    CFRelease(metadata);
	
	return self;
}

- (id)initWithTrackDictionary:(NSDictionary *)track source:(SongSource)source
{
	NSParameterAssert(track);
	
	if(source == kSongSourceITunes)
	{
		NSString *locationString = [track objectForKey:@"Location"];
		if(!locationString)
			return nil;
		
		if([[track objectForKey:@"Kind"] isEqualToString:@"Audible file"])
			return nil;
		
		mLocation = [NSURL URLWithString:locationString];
		if(!RKIsLocationWithinSandbox(mLocation))
			return nil;
		
		if((self = [super init]))
		{
			mSourceIdentifier = [[track objectForKey:@"Track ID"] stringValue];
			
			mName = [[track objectForKey:@"Name"] copy] ?: [[mLocation lastPathComponent] stringByDeletingPathExtension];
			mArtist = [[track objectForKey:@"Artist"] copy] ?: kArtistPlaceholderName;
			mAlbum = [[track objectForKey:@"Album"] copy] ?: kAlbumPlaceholderName;
			if([mAlbum length] == 0)
				mAlbum = kAlbumPlaceholderName;
			
			mAlbumArtist = [[track objectForKey:@"Album Artist"] copy] ?: mArtist;
			mGenre = [[track objectForKey:@"Genre"] copy];
			mTrackNumber = [[track objectForKey:@"Track Number"] integerValue];
			mDiscNumber = [[track objectForKey:@"Disc Number"] integerValue];
			
			mDuration = [[track objectForKey:@"Total Time"] doubleValue] / 1000.0;
			mStartTime = [[track objectForKey:@"Start Time"] doubleValue] / 1000.0;
			mStopTime = [[track objectForKey:@"Stop Time"] doubleValue] / 1000.0;
			mIsProtected = [[track objectForKey:@"Protected"] boolValue];
			mHasVideo = [[track objectForKey:@"Has Video"] boolValue];
			mDisabled = [[track objectForKey:@"Disabled"] boolValue];
			mIsCompilation = [[track objectForKey:@"Compilation"] boolValue];
		}
	}
	else if(source == kSongSourceExfm)
	{
		NSString *locationString = RKFilterOutNSNull([track objectForKey:@"url"]);
		if(!locationString)
			return nil;
		
		if((self = [super init]))
		{
			if([locationString rangeOfString:@"soundcloud.com"].location != NSNotFound)
			{
				if([locationString rangeOfString:@"?"].location == NSNotFound)
					locationString = [locationString stringByAppendingFormat:@"?consumer_key=%@", kSoundcloudConsumerKey];
				else
					locationString = [locationString stringByAppendingFormat:@"&consumer_key=%@", kSoundcloudConsumerKey];
			}
			
			mLocation = [NSURL URLWithString:locationString];
			
			mSourceIdentifier = RKFilterOutNSNull([track objectForKey:@"id"]);
			
			mName = [RKFilterOutNSNull([track objectForKey:@"title"]) copy] ?: [[mLocation lastPathComponent] stringByDeletingPathExtension];
			mArtist = [RKFilterOutNSNull([track objectForKey:@"artist"]) copy] ?: kArtistPlaceholderName;
			mAlbum = [RKFilterOutNSNull([track objectForKey:@"album"]) copy] ?: kAlbumPlaceholderName;
			if([mAlbum length] == 0)
				mAlbum = kAlbumPlaceholderName;
			
			mAlbumArtist = mArtist;
			mGenre = [RKFilterOutNSNull([track objectForKey:@"tags"]) componentsJoinedByString:@", "];
			
			mDuration = 0.0;
			
			NSDictionary *artworkLocationsSourceData = RKFilterOutNSNull([track objectForKey:@"image"]);
			NSMutableDictionary *artworkLocations = [NSMutableDictionary dictionary];
			if(RKFilterOutNSNull([artworkLocationsSourceData objectForKey:@"small"]))
				[artworkLocations setObject:[NSURL URLWithString:[artworkLocationsSourceData objectForKey:@"small"]] forKey:@"small"];
			
			if(RKFilterOutNSNull([artworkLocationsSourceData objectForKey:@"medium"]))
				[artworkLocations setObject:[NSURL URLWithString:[artworkLocationsSourceData objectForKey:@"medium"]] forKey:@"medium"];
			
			if(RKFilterOutNSNull([artworkLocationsSourceData objectForKey:@"large"]))
				[artworkLocations setObject:[NSURL URLWithString:[artworkLocationsSourceData objectForKey:@"large"]] forKey:@"large"];
			
			mRemoteArtworkLocations = artworkLocations;
			
			mSongSource = kSongSourceExfm;
		}
	}
	
	return self;
}

#pragma mark - Property Gunk

@synthesize location = mLocation;
@synthesize sourceIdentifier = mSourceIdentifier;

- (NSString *)uniqueIdentifier
{
	if(!mPregeneratedUniqueIdentifier)
		mPregeneratedUniqueIdentifier = RKGenerateIdentifierForStrings(@[self.name ?: @"", self.artist ?: @"", self.album ?: @""]);
	
	return mPregeneratedUniqueIdentifier;
}

- (NSString *)universalIdentifier
{
	return self.uniqueIdentifier;
}

- (NSDictionary *)shortSong
{
    NSMutableDictionary *shortSong = [NSMutableDictionary dictionary];
    [shortSong setValue:self.name forKey:@"name"];
    [shortSong setValue:self.artist forKey:@"artist"];
    [shortSong setValue:self.album forKey:@"album"];
    [shortSong setValue:self.universalIdentifier forKey:@"universalIdentifier"];
    return shortSong;
}

#pragma mark -

@synthesize name = mName;
@synthesize artist = mArtist;
@synthesize album = mAlbum;
@synthesize albumArtist = mAlbumArtist;
@synthesize genre = mGenre;
@synthesize trackNumber = mTrackNumber;
@synthesize discNumber = mDiscNumber;
@synthesize rating = mRating;

#pragma mark -

@synthesize duration = mDuration;
@synthesize startTime = mStartTime;
@synthesize stopTime = mStopTime;
@synthesize isProtected = mIsProtected;
@synthesize hasVideo = mHasVideo;
@synthesize disabled = mDisabled;
@synthesize isCompilation = mIsCompilation;

#pragma mark -

@synthesize lastPlayed = mLastPlayed;
@synthesize songSource = mSongSource;

#pragma mark - Transient Properties

@synthesize remoteArtworkLocations = mRemoteArtworkLocations;

#pragma mark - Identity

- (NSUInteger)hash
{
	return 4 + ([mLocation hash] << 1);
}

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[Song class]])
		return [self isEqualToSong:object];
	
	return NO;
}

- (BOOL)isEqualToSong:(Song *)song
{
	NSString *leftTrackIdentifier = self.sourceIdentifier;
	NSString *rightTrackIdentifier = song.sourceIdentifier;
	if((leftTrackIdentifier && rightTrackIdentifier) && 
	   ![leftTrackIdentifier isEqualToString:rightTrackIdentifier])
	{
		return NO;
	}
	
	return [self.location isEqualTo:song.location];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@>", [self className], self, self.location];
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
	
	return [NSPredicate predicateWithBlock:^(Song *song, NSDictionary *bindings) {
		return RKCollectionDoAllValuesMatch(searchQueryParts, ^BOOL(NSString *queryPart) {
			if([queryPart length] == 0)
				return YES;
			
			BOOL(^doesMatchSearchStringPart)(NSString *) = ^BOOL(NSString *fieldValue) {
				return fieldValue && [fieldValue rangeOfString:queryPart 
													   options:(NSCaseInsensitiveSearch | 
																NSDiacriticInsensitiveSearch | 
																NSWidthInsensitiveSearch)].location != NSNotFound;
			};
			
			return (doesMatchSearchStringPart(song.name) ||
					doesMatchSearchStringPart(song.artist) ||
					doesMatchSearchStringPart(song.album) ||
					doesMatchSearchStringPart(song.genre));
		});
	}];
}

#pragma mark - <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder
{
	if((self = [super init]))
	{
		NSInteger songArchiveVersion = [decoder decodeIntegerForKey:@"SongArchiveVersion"];
		NSAssert(songArchiveVersion == kSongArchiveVersionInitial, @"Unexpected song archive version %ld", songArchiveVersion);
		
		mSourceIdentifier = [decoder decodeObjectForKey:@"sourceIdentifier"];
		mLocation = [decoder decodeObjectForKey:@"location"];
		
		mName = [decoder decodeObjectForKey:@"name"];
		mArtist = [decoder decodeObjectForKey:@"artist"];
		mAlbum = [decoder decodeObjectForKey:@"album"];
		mAlbumArtist = [decoder decodeObjectForKey:@"albumArtist"];
		mGenre = [decoder decodeObjectForKey:@"genre"];
		mTrackNumber = [decoder decodeIntegerForKey:@"trackNumber"];
		mDiscNumber = [decoder decodeIntegerForKey:@"discNumber"];
		mRating = [decoder decodeFloatForKey:@"rating"];
		
		mDuration = [decoder decodeDoubleForKey:@"duration"];
		mStartTime = [decoder decodeDoubleForKey:@"startTime"];
		mStopTime = [decoder decodeDoubleForKey:@"stopTime"];
		mHasVideo = [decoder decodeBoolForKey:@"hasVideo"];
		mIsProtected = [decoder decodeBoolForKey:@"isProtected"];
		mDisabled = [decoder decodeBoolForKey:@"disabled"];
		mIsCompilation = [decoder decodeBoolForKey:@"isCompilation"];
		
		mLastPlayed = [decoder decodeObjectForKey:@"lastPlayed"];
		mSongSource = [decoder decodeIntegerForKey:@"songSource"];
		
		mRemoteArtworkLocations = [decoder decodeObjectForKey:@"remoteArtworkLocations"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeInteger:kSongArchiveVersionInitial forKey:@"SongArchiveVersion"];
	
	[encoder encodeObject:mSourceIdentifier forKey:@"sourceIdentifier"];
	[encoder encodeObject:mLocation forKey:@"location"];
	
	[encoder encodeObject:mName forKey:@"name"];
	[encoder encodeObject:mArtist forKey:@"artist"];
	[encoder encodeObject:mAlbum forKey:@"album"];
	[encoder encodeObject:mAlbumArtist forKey:@"albumArtist"];
	[encoder encodeObject:mGenre forKey:@"genre"];
	[encoder encodeInteger:mTrackNumber forKey:@"trackNumber"];
	[encoder encodeInteger:mDiscNumber forKey:@"discNumber"];
	[encoder encodeFloat:mRating forKey:@"rating"];
	
	[encoder encodeDouble:mDuration forKey:@"duration"];
	[encoder encodeDouble:mStartTime forKey:@"startTime"];
	[encoder encodeDouble:mStopTime forKey:@"stopTime"];
	[encoder encodeBool:mHasVideo forKey:@"hasVideo"];
	[encoder encodeBool:mIsProtected forKey:@"isProtected"];
	[encoder encodeBool:mDisabled forKey:@"disabled"];
	[encoder encodeBool:mIsCompilation forKey:@"isCompilation"];
	
	[encoder encodeObject:mLastPlayed forKey:@"lastPlayed"];
	[encoder encodeInteger:mSongSource forKey:@"songSource"];
	
	[encoder encodeObject:mRemoteArtworkLocations forKey:@"remoteArtworkLocations"];
}

#pragma mark - <NSPasteboardReading>

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return @[kSongUTI];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
	return NSPasteboardReadingAsKeyedArchive;
}

#pragma mark - <NSPasteboardWriting>

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
	return @[kSongUTI];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
	if([type isEqualToString:kSongUTI])
		return [NSKeyedArchiver archivedDataWithRootObject:self];
	
	return nil;
}

@end
