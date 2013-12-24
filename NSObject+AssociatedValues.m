//
//  NSObject+AssociatedValues.m
//  Pinna
//
//  Created by Peter MacWhinnie on 11/30/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "NSObject+AssociatedValues.h"
#import <objc/runtime.h>

static NSString *const kAssociatedValuesDictionaryKey = @"NSObject.Convenience.AssociatedValuesDictionary";

@implementation NSObject (AssociatedValues)

#pragma mark Object Associations

- (void)setAssociatedValue:(id)value forKey:(NSString *)key
{
	NSParameterAssert(key);
	
	@synchronized(self)
	{
		NSMutableDictionary *associatedValues = objc_getAssociatedObject(self, (__bridge void *)kAssociatedValuesDictionaryKey);
		if(!associatedValues)
		{
			associatedValues = [NSMutableDictionary new];
			objc_setAssociatedObject(self, (__bridge void *)kAssociatedValuesDictionaryKey, associatedValues, OBJC_ASSOCIATION_RETAIN);
		}
		
		if(value)
			[associatedValues setObject:value forKey:key];
		else
			[associatedValues removeObjectForKey:key];
	}
}

- (id)associatedValueForKey:(NSString *)key
{
	NSParameterAssert(key);
	
	@synchronized(self)
	{
		NSMutableDictionary *associatedValues = objc_getAssociatedObject(self, (__bridge void *)kAssociatedValuesDictionaryKey);
		return [associatedValues objectForKey:key];
	}
}

@end
