//
//  MediaKeyEventTap.m
//  event-spy
//
//  Created by Peter MacWhinnie on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MediaKeyEventTap.h"

@implementation MediaKeyEventTap {
	CFMachPortRef _eventTap;
	CFRunLoopSourceRef _eventTapRunLoopSource;
}

static CGEventRef EventTapCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userData)
{
	MediaKeyEventTap *self = (__bridge MediaKeyEventTap *)userData;
	if(type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
		CGEventTapEnable(self->_eventTap, true);
		return event;
	}
	
	@try {
		NSEvent *cocoaEvent = [NSEvent eventWithCGEvent:event];
		if(([cocoaEvent type] == NSSystemDefined) && ([cocoaEvent subtype] == 8)) {
			//The following 4 lines are from <http://www.rogueamoeba.com/utm/2007/09/29/>
			MediaKeyCode keyCode = (([cocoaEvent data1] & 0xFFFF0000) >> 16);
			NSInteger keyFlags = ([cocoaEvent data1] & 0x0000FFFF);
			BOOL isKeyDown = (((keyFlags & 0xFF00) >> 8)) == 0xA;
			BOOL isKeyHeldDown = (keyFlags & 0x1);
			
			//This prevents us from stealing events we shouldn't be.
			if((keyCode != kMediaKeyCodePlayPause) &&
			   (keyCode != kMediaKeyCodeNext) &&
			   (keyCode != kMediaKeyCodePrevious)) {
				return event;
			}
			
			//Dispatch the event we've just received from the delegate
			MediaKeyEventTap *self = (__bridge MediaKeyEventTap *)userData;
			id < MediaKeyEventTapDelegate > delegate = self.delegate;
			if(isKeyHeldDown) {
				if([delegate respondsToSelector:@selector(mediaKeyEventTap:mediaKeyIsBeingHeld:)]) {
					if([delegate mediaKeyEventTap:self mediaKeyIsBeingHeld:keyCode])
						return NULL;
				}
			} else if(isKeyDown) {
				if([delegate mediaKeyEventTap:self mediaKeyWasPressed:keyCode])
					return NULL;
			} else {
				if([delegate mediaKeyEventTap:self mediaKeyWasReleased:keyCode])
					return NULL;
			}
		}
	}
	@catch (NSException *e) {
		//We catch any exceptions to prevent the event tap from being messed up.
        NSLog(@"*** MediaKeyEventTap captured and ignoring exception: %@", e);
	}
	
	return event;
}

- (void)reclaimEventTap
{
	if(self.enabled) {
		//Reset the tap
		CGEventTapEnable(_eventTap, false);
		CGEventTapEnable(_eventTap, true);
	}
}

#pragma mark - Lifecycle

static MediaKeyEventTap *sharedMediaKeyEventTap = nil;
+ (MediaKeyEventTap *)sharedMediaKeyEventTap
{
	static dispatch_once_t predicate = 0;
	dispatch_once(&predicate, ^{
		sharedMediaKeyEventTap = [MediaKeyEventTap new];
	});
	
	return sharedMediaKeyEventTap;
}

#pragma mark -

- (void)dealloc
{
	if(_eventTapRunLoopSource) {
		CFRunLoopRemoveSource(CFRunLoopGetMain(), _eventTapRunLoopSource, kCFRunLoopCommonModes);
		CFRelease(_eventTapRunLoopSource);
		_eventTapRunLoopSource = NULL;
	}
	
	if(_eventTap) {
		CFRelease(_eventTap);
		_eventTap = NULL;
	}
}

- (id)init
{
	if((self = [super init])) {
        _eventTap = CGEventTapCreate(kCGSessionEventTap, //tapLocation
                                     kCGHeadInsertEventTap, //tapPlacement
                                     kCGEventTapOptionDefault, //options
                                     CGEventMaskBit(NX_SYSDEFINED), //eventsOfInterest
                                     &EventTapCallBack, //callback
                                     (__bridge void *)self); //callbackUserInfo
        
        if(!_eventTap) {
            NSLog(@"Could not create event tap for media keys (CGEventTapCreate).");
            return nil;
        }
        
        _eventTapRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0);
        if(!_eventTapRunLoopSource) {
            CFRelease(_eventTap);
            _eventTap = NULL;
            
            NSLog(@"Could not create event tap for media keys (CFMachPortCreateRunLoopSource).");
            return nil;
        }
        
        CFRunLoopAddSource(CFRunLoopGetMain(), _eventTapRunLoopSource, kCFRunLoopCommonModes);
        
        CGEventTapEnable(_eventTap, true);
        
        NSNotificationCenter *workspaceNotificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
        [workspaceNotificationCenter addObserver:self
                                        selector:@selector(reclaimEventTap)
                                            name:NSWorkspaceDidLaunchApplicationNotification
                                          object:nil];
        [workspaceNotificationCenter addObserver:self
                                        selector:@selector(reclaimEventTap)
                                            name:NSWorkspaceDidTerminateApplicationNotification
                                          object:nil];
        [workspaceNotificationCenter addObserver:self 
                                        selector:@selector(reclaimEventTap) 
                                            name:NSWorkspaceDidWakeNotification 
                                          object:nil];
		
		return self;
	}
	return nil;
}

#pragma mark - Properties

- (void)setEnabled:(BOOL)enabled
{
	CGEventTapEnable(_eventTap, enabled);
}

- (BOOL)enabled
{
    return CGEventTapIsEnabled(_eventTap);
}

@end
