//
//  LastFMDefines.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/13/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef Pinna_LastFMDefines_h
#define Pinna_LastFMDefines_h

//Uncomment the following define to have Last.fm use
//our non-commercial public and private keys, and to use
//the non-commercial user defaults keys.
//#define BUILD_LASTFM_FOR_INTERNAL 1

///The user defaults key for the cached Last.fm session key.
RK_EXTERN NSString *const kLastFMSessionDefaultsKey DEPRECATED_ATTRIBUTE;

///The user defaults key for the cached Last.fm user info.
RK_EXTERN NSString *const kLastFMCachedUserInfoDefaultsKey;


///Our Last.fm public key.
RK_EXTERN NSString *const kLastFMPublicKey;

///Our Last.fm shared secret.
RK_EXTERN NSString *const kLastFMSecret;

#endif
