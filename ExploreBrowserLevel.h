//
//  DiscoveryBrowserLevel.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/19/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKBrowserLevel.h"

@class Library;

@interface ExploreBrowserLevel : RKBrowserLevel
{
	Library *mLibrary;
	
	NSArray *mCachedTrending;
	NSTimer *mTrendingUpdateTimer;
	
	NSArray *mResults;
	
	NSUInteger mResultsOffset;
	
	BOOL mIsLoadingMoreResults;
	
	NSCache *mArtworkCache;
	NSMutableSet *mArtworkBeingDownloaded;
	NSOperationQueue *mArtworkDownloadQueue;
}

///Whether or not the browser is searching.
@property (nonatomic, readonly) BOOL isSearching;

@end
