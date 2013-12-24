//
//  SongsBrowserLevel.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/1/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserLevel.h"

@class Library;

@interface SongsBrowserLevel : RKBrowserLevel
{
	Library *mLibrary;
	
	BOOL mIsValid;
	BOOL mIsObservingPlaylistChanges;
	BOOL mShowsArtwork;
	id mParent;
	NSPredicate *mFetchPredicate;
}

#pragma mark Properties

///The parent whose content we are to display.
///
///This property may be set to an Artist, Album, or Playlist.
@property (nonatomic) id parent;

///Whether or not the browser shows artwork.
@property (nonatomic) BOOL showsArtwork;

@end
