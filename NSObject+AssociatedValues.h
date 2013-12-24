//
//  NSObject+AssociatedValues.h
//  Pinna
//
//  Created by Peter MacWhinnie on 11/30/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///
///	The AssociatedValues category on NSObject adds methods to associate
///	arbitrary values with an instance of NSObject in a thread-safe manner.
///
@interface NSObject (AssociatedValues)

#pragma mark Object Associations

///Associates an arbitrary object with the receiver using a specified key. Thread safe.
- (void)setAssociatedValue:(id)value forKey:(NSString *)key;

///Returns the value associated with a specified key. Thread safe.
- (id)associatedValueForKey:(NSString *)key;

@end
