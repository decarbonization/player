//
//  RKKeyDispatcher.m
//  Pinna
//
//  Created by Peter MacWhinnie on 3/12/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import "RKKeyDispatcher.h"

@implementation RKKeyDispatcher

- (id)init
{
	if((self = [super init]))
	{
		mHandlers = [NSMutableDictionary new];
	}
	
	return self;
}

- (void)setHandlerForKeyCode:(unichar)keyCode block:(RKKeyDispatcherHandler)block
{
	NSParameterAssert(block);
	
	@synchronized(mHandlers)
	{
		[mHandlers setObject:[block copy] forKey:[NSNumber numberWithLong:keyCode]];
	}
}

- (void)removeHandlerForKeyCode:(unichar)keyCode
{
	@synchronized(mHandlers)
	{
		[mHandlers removeObjectForKey:[NSNumber numberWithLong:keyCode]];
	}
}

- (RKKeyDispatcherHandler)handlerForKeyCode:(unichar)keyCode
{
	@synchronized(mHandlers)
	{
		return [mHandlers objectForKey:[NSNumber numberWithLong:keyCode]];
	}
}

- (BOOL)dispatchKey:(unichar)keyCode withModifiers:(NSUInteger)modifiers
{
	@synchronized(mHandlers)
	{
		RKKeyDispatcherHandler block = [self handlerForKeyCode:keyCode];
		if(block)
			return block(modifiers);
	}
	
	return NO;
}

@end
