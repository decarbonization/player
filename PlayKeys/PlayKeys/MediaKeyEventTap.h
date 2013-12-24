//
//  MediaKeyEventTap.h
//  event-spy
//
//  Created by Peter MacWhinnie on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/hidsystem/ev_keymap.h>

@protocol MediaKeyEventTapDelegate;

///The key codes that will be given to a delegate of the MediaKeyEventTap class.
typedef NS_ENUM(short, MediaKeyCode) {
	///The "play pause" media key's key code.
	kMediaKeyCodePlayPause = NX_KEYTYPE_PLAY,
	
	///The "next" media key's key code.
	kMediaKeyCodeNext = NX_KEYTYPE_FAST,
	
	///The "previous" media key's key code.
	kMediaKeyCodePrevious = NX_KEYTYPE_REWIND,
};


///The MediaKeyEventTap class encapsulates listening for events related to the
///media keys on Apple keyboards and notifies its delegate of said events.
@interface MediaKeyEventTap : NSObject

///Returns the shared media key watcher, creating it if it doesn't exist.
+ (MediaKeyEventTap *)sharedMediaKeyEventTap;

#pragma mark - Properties

///The delegate of the media key watcher.
@property (nonatomic, weak) id <MediaKeyEventTapDelegate> delegate;

///Whether or not the media key watcher is enabled.
@property (nonatomic) BOOL enabled;

@end

#pragma mark -

///The MediaKeyEventTapDelegate protocol describes the methods
///required for an object to be a delegate of MediaKeyEventTap.
@protocol MediaKeyEventTapDelegate <NSObject>
@required

///Invoked when a media key watcher receives a key down event for a media key.
///
/// \param  watcher The watcher that received the key down event.
/// \param  key     The key code of the media key pressed.
///
/// \result YES if the delegate has handled the media key event and it should not be propagated; NO otherwise.
///
- (BOOL)mediaKeyEventTap:(MediaKeyEventTap *)watcher mediaKeyWasPressed:(MediaKeyCode)key;

///Invoked when a media key watcher receives a key up event for a media key.
///
/// \param  watcher The watcher that received the key up event.
/// \param  key     The key code of the media key released.
///
/// \result YES if the delegate has handled the media key event and it should not be propagated; NO otherwise.
///
- (BOOL)mediaKeyEventTap:(MediaKeyEventTap *)watcher mediaKeyWasReleased:(MediaKeyCode)key;

@optional

///Invoked when a media key watcher notices that a media key is being held down.
/// \param  watcher The watcher that noticed the media key being held down.
/// \param  key     The key code of the media key being held down.
///
/// \result YES if the delegate has handled the media key event and it should not be propagated; NO otherwise.
///
- (BOOL)mediaKeyEventTap:(MediaKeyEventTap *)watcher mediaKeyIsBeingHeld:(MediaKeyCode)key;

@end
