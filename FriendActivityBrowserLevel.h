//
//  FriendActivityBrowserLevel.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 9/29/12.
//
//

#import "RKBrowserLevel.h"

@class Library, ExfmSession;
@interface FriendActivityBrowserLevel : RKBrowserLevel
{
	Library *mLibrary;
    ExfmSession *mExfmSession;
	
	NSArray *mCachedActors;
	NSArray *mCachedSongs;
	
	NSCache *mArtworkCache;
	NSMutableSet *mArtworkBeingDownloaded;
	NSOperationQueue *mArtworkDownloadQueue;
}

@end
