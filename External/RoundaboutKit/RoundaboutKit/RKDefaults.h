//
//  RKDefaults.h
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#ifndef RKDefaults_h
#define RKDefaults_h 1

#import <Foundation/Foundation.h>
#import "RKPrelude.h"

///Short-hand for interacting with the user defaults.

#pragma mark Defaults Short-hand

///Persist an object into the user defaults.
RK_EXTERN id RKSetPersistentObject(NSString *key, id object);

///Get an object persisted into the user defaults.
RK_EXTERN id RKGetPersistentObject(NSString *key);

#pragma mark -

///Persist an integer into the user defaults.
RK_EXTERN NSInteger RKSetPersistentInteger(NSString *key, NSInteger value);

///Get an object persisted into the user defaults.
RK_EXTERN NSInteger RKGetPersistentInteger(NSString *key);

#pragma mark -

///Persist an integer into the user defaults.
RK_EXTERN float RKSetPersistentFloat(NSString *key, float value);

///Get an object persisted into the user defaults.
RK_EXTERN float RKGetPersistentFloat(NSString *key);

#pragma mark -

///Persist an integer into the user defaults.
RK_EXTERN BOOL RKSetPersistentBool(NSString *key, BOOL value);

///Get an object persisted into the user defaults.
RK_EXTERN BOOL RKGetPersistentBool(NSString *key);

#pragma mark -

///Returns a boolean indicating whether or not a persistent value exists.
RK_EXTERN BOOL RKPersistentValueExists(NSString *key);

#pragma mark - Testing Support

///Turns off the persistent backing of the RKDefaults functions. Intended for use with unit tests.
RK_EXTERN void RKDefaultsActivateTestMode();

#endif /* RKDefaults_h */
