//
//  LastFMDefines.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/13/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "LastFMDefines.h"

#if BUILD_LASTFM_FOR_INTERNAL

#warning Building Last.fm for Internal Testing

NSString *const kLastFMSessionDefaultsKey = @"LastFMSessionKey";
NSString *const kLastFMCachedUserInfoDefaultsKey = @"LastFM_cachedUserInfo";

NSString *const kLastFMPublicKey = @"c9e43d974b1851ad62b617b8b4a24749";
NSString *const kLastFMSecret = @"afb90a915ba30d52ef4cc4744ed2fc5b";

#else

NSString *const kLastFMSessionDefaultsKey = @"LastFMSessionKey_Deployment";
NSString *const kLastFMCachedUserInfoDefaultsKey = @"LastFM_cachedUserInfo_Deployment";

NSString *const kLastFMPublicKey = @"c28ced55bab8f035de0e0f33479f749d";
NSString *const kLastFMSecret = @"c3c1b6d9f808dc617acbc9ba6997444d";

#endif /* BUILD_LASTFM_FOR_INTERNAL */