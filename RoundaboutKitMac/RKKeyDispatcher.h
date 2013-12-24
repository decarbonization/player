//
//  RKKeyDispatcher.h
//  Pinna
//
//  Created by Peter MacWhinnie on 3/12/11.
//  Copyright 2011 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The block type used as a callback for RKKeyDispatcher.
typedef BOOL(^RKKeyDispatcherHandler)(NSUInteger pressedModifiers);

///The key listener class provides an object for dispatching specific key presses
///to different blocks. Used by BKBorderlessWindow to implement key event handling.
@interface RKKeyDispatcher : NSObject
{
	NSMutableDictionary *mHandlers;
}

///Sets the block for a specified key code.
///	\param	keyCode		The key code to listen for.
///	\param	block		The block to invoke to try to handle the key combo. \see(RKKeyDispatcherBlock).
- (void)setHandlerForKeyCode:(unichar)keyCode block:(RKKeyDispatcherHandler)block;

///Removes the handler for a specified key code.
- (void)removeHandlerForKeyCode:(unichar)keyCode;

///Returns the block for a specified key code.
- (RKKeyDispatcherHandler)handlerForKeyCode:(unichar)keyCode;

///Try to handle a specified key code with specified modifier keys.
///
///	\param	keyCode		The key code to handle.
///	\param	modifiers	The pressed modifier keys.
- (BOOL)dispatchKey:(unichar)keyCode withModifiers:(NSUInteger)modifiers;

@end
