//
//  MediaKeyWatcher.h
//  event-spy
//
//  Created by Peter MacWhinnie on 8/26/09.
//  Copyright 2009 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/hidsystem/ev_keymap.h>

@protocol PlayKeysBridgeDelegate;

typedef enum _MediaKeyCode {
	/*!
	 @enum		MediaKeyCode
	 @abstract	The key codes that will be given to a delegate of the MediaKeyWatcher class.
	 */
	
	
	/*!
	 @constant
	 @abstract	The "play pause" media key's key code.
	 */
	kMediaKeyCodePlayPause = NX_KEYTYPE_PLAY,
	
	/*!
	 @constant
	 @abstract	The "next" media key's key code.
	 */
	kMediaKeyCodeNext = NX_KEYTYPE_FAST,
	
	/*!
	 @constant
	 @abstract	The "previous" media key's key code.
	 */
	kMediaKeyCodePrevious = NX_KEYTYPE_REWIND,
} MediaKeyCode;


///The PlayKeysBridge wraps up communication with the PlayKeys app, 
///allowing Pinna to use the media keys on the keyboard.
@interface PlayKeysBridge : NSObject
{
	/** Internal **/
	
	CFMachPortRef mEventTap;
	CFRunLoopSourceRef mEventTapRunLoopSource;
	
	/** Properties **/
	
	BOOL mEnabled;
	__unsafe_unretained id mDelegate;
}
#pragma mark Singletonness

///Returns the shared media key watcher, creating it if it doesn't exist.
+ (PlayKeysBridge *)playKeysBridge;

#pragma mark - Properties

///The delegate.
@property (nonatomic, assign) id <PlayKeysBridgeDelegate> delegate;

///Whether or not we should respond to media key events.
@property (nonatomic) BOOL enabled;

#pragma mark - Controlling PlayKeys.app

///Whether or not the PlayKeys application is running.
@property (nonatomic, readonly) BOOL isPlayKeysAppRunning;

///The location of the PlayKeys application, if it's installed.
@property (nonatomic, readonly) NSURL *playKeysAppLocation;

///Whether or not the PlayKeys application is installed.
@property (nonatomic, readonly) BOOL isPlayKeysAppInstalled;

#pragma mark -

///Launches the PlayKeys companion app.
- (void)launchPlayKeysApp;

///Asks the PlayKeys companion app to terminate.
///
///This method does not need to be called when Pinna terminates,
///PlayKeys is monitoring for Pinna's termination and has special
///logic in place to keep it running when there's more then one
///instance of Pinna running.
- (void)terminatePlayKeysApp;

@end

#pragma mark -

///The methods required for an object to be a delegate of PlayKeysBridge.
@protocol PlayKeysBridgeDelegate <NSObject>
@required

///Invoked when a media key is pressed.
- (void)playKeysBridge:(PlayKeysBridge *)bridge mediaKeyWasPressed:(MediaKeyCode)key;

///Invoked when a media key is released.
- (void)playKeysBridge:(PlayKeysBridge *)bridge mediaKeyWasReleased:(MediaKeyCode)key;

@optional

///Invoked when a media key is held down.
- (void)playKeysBridge:(PlayKeysBridge *)bridge mediaKeyIsBeingHeld:(MediaKeyCode)key;

@end
