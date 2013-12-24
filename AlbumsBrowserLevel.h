//
//  AlbumsBrowserLevel.h
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 2/12/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserLevel.h"

@class Library, Artist;
@interface AlbumsBrowserLevel : RKBrowserLevel
{
	Library *mLibrary;
	
	Artist *mParentArtist;
}

#pragma mark Properties

///The parent artist of the albums to filter by, if any.
@property (nonatomic) Artist *parentArtist;

@end
