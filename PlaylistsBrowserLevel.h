//
//  PlaylistsBrowserLevel.h
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 2/12/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserLevel.h"

@class Library, Playlist;
@class FriendActivityBrowserLevel;
@interface PlaylistsBrowserLevel : RKBrowserLevel
{
	Library *mLibrary;
	
	Playlist *mFriendActivityLevelPlaylist;
	FriendActivityBrowserLevel *mFriendActivityLevel;
    
    NSMutableArray *mPlaylists;
}

@end
