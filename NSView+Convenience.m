//
//  NSView+Convenience.m
//  Player
//
//  Created by Peter MacWhinnie on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSView+Convenience.h"
#import "NSObject+AssociatedValues.h"

@implementation NSView (BKConvenience)

- (void)setFirstKeyView:(NSView *)view
{
	[self setAssociatedValue:view forKey:@"firstKeyView"];
}

- (NSView *)firstKeyView
{
	return [self associatedValueForKey:@"firstKeyView"];
}

- (void)setName:(NSString *)name
{
	[self setAssociatedValue:[name copy] forKey:@"name"];
}

- (NSString *)name
{
	return [self associatedValueForKey:@"name"];
}

@end
