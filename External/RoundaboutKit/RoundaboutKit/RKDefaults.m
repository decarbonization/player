//
//  RKDefaults.m
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKDefaults.h"

static BOOL _TestMode = NO;

static NSMutableDictionary *TestModeBackingDictionary()
{
    static NSMutableDictionary *testModeBackingDictionary = nil;
    if(!testModeBackingDictionary)
        testModeBackingDictionary = [NSMutableDictionary dictionary];
    
    return testModeBackingDictionary;
}

#pragma mark Defaults Short-hand

id RKSetPersistentObject(NSString *key, id object)
{
	NSCParameterAssert(key);
    
    if(_TestMode)
        [TestModeBackingDictionary() setValue:object forKey:key];
    else
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
	
    return object;
}

id RKGetPersistentObject(NSString *key)
{
	NSCParameterAssert(key);
	if(_TestMode)
        return [TestModeBackingDictionary() objectForKey:key];
    else
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

#pragma mark -

NSInteger RKSetPersistentInteger(NSString *key, NSInteger value)
{
	NSCParameterAssert(key);
	RKSetPersistentObject(key, @(value));
	return value;
}

NSInteger RKGetPersistentInteger(NSString *key)
{
	NSCParameterAssert(key);
	return [RKGetPersistentObject(key) integerValue];
}

#pragma mark -

float RKSetPersistentFloat(NSString *key, float value)
{
	NSCParameterAssert(key);
	RKSetPersistentObject(key, @(value));
	return value;
}

float RKGetPersistentFloat(NSString *key)
{
	NSCParameterAssert(key);
	return [RKGetPersistentObject(key) floatValue];
}

#pragma mark -

BOOL RKSetPersistentBool(NSString *key, BOOL value)
{
	NSCParameterAssert(key);
    RKSetPersistentObject(key, @(value));
	return value;
}

BOOL RKGetPersistentBool(NSString *key)
{
	NSCParameterAssert(key);
	return [RKGetPersistentObject(key) boolValue];
}

#pragma mark -

BOOL RKPersistentValueExists(NSString *key)
{
	NSCParameterAssert(key);
    if(_TestMode)
        return ([TestModeBackingDictionary() objectForKey:key] != nil);
    else
        return ([[NSUserDefaults standardUserDefaults] objectForKey:key] != nil);
}

#pragma mark - Testing Support

void RKDefaultsActivateTestMode()
{
    _TestMode = YES;
}
