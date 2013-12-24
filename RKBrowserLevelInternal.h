//
//  RKBrowserLevelInternal.h
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 2/12/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserLevel.h"

///The internal support methods for RKBrowserLevel
@interface RKBrowserLevel ()

///	\ignore
///	\see(-[RKBrowserLevel parentBrowser])
@property (nonatomic, readwrite) RKBrowserView *parentBrowser;

#pragma mark -

///The cached previous browser level.
@property (nonatomic) RKBrowserLevel *cachedPreviousLevel;

///The cached next browser level.
@property (nonatomic) RKBrowserLevel *cachedNextLevel;

///Returns the deepest cached level, starting with the receiver.
- (RKBrowserLevel *)deepestCachedLevel;

///Returns the shallowest level, starting with the receiver.
- (RKBrowserLevel *)shallowestLevel;

#pragma mark -

///The controller of the browser level.
///
///This property is lazily initialized.
@property (nonatomic) RKBrowserLevelController *controller;

@end
