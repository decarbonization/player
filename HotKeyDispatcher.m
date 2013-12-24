//
//  HotKeyDispatcher.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/24/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "HotKeyDispatcher.h"

static OSStatus HotKeyEventHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData);

NSDictionary *KeyComboToDictionary(KeyCombo keyCombo)
{
	return @{
        @"code": [NSNumber numberWithInteger:keyCombo.code],
        @"flags": [NSNumber numberWithUnsignedInteger:keyCombo.flags],
    };
}

KeyCombo KeyComboFromDictionary(NSDictionary *dictionary)
{
	if(!dictionary)
		return SRMakeKeyCombo(-1, 0);
	
	return SRMakeKeyCombo([[dictionary objectForKey:@"code"] integerValue], 
						  [[dictionary objectForKey:@"flags"] unsignedIntegerValue]);
}

@implementation HotKeyDispatcher

static HotKeyDispatcher *sharedHotKeyDispatcher = nil;
+ (HotKeyDispatcher *)sharedHotKeyDispatcher
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedHotKeyDispatcher = [HotKeyDispatcher new];
	});
	
	return sharedHotKeyDispatcher;
}

- (id)init
{
	if((self = [super init]))
	{
		EventTypeSpec eventType = {
			.eventClass = kEventClassKeyboard,
			.eventKind = kEventHotKeyPressed,
		};
		OSStatus error = InstallApplicationEventHandler(&HotKeyEventHandler, 1, &eventType, (__bridge void *)self, NULL);
		if(error != noErr)
		{
			NSLog(@"Could not install hot key handler. Error %d", error);
			
			return nil;
		}
		
		mPlayPauseCombo.code = mNextTrackCombo.code = mPreviousTrackCombo.code = -1;
	}
	
	return self;
}

#pragma mark -

static OSStatus HotKeyEventHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData)
{
	HotKeyDispatcher *self = (__bridge HotKeyDispatcher *)userData;
	
	EventHotKeyID hotKeyID;
	GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID), NULL, &hotKeyID);
	
	switch (hotKeyID.id)
	{
		case 1: //play-pause
			[self->mDelegate hotKeyDispatcherDetectedPlayPause:self];
			break;
			
		case 2: //next track
			[self->mDelegate hotKeyDispatcherDetectedNextTrack:self];
			break;
			
		case 3: //previous track
			[self->mDelegate hotKeyDispatcherDetectedPreviousTrack:self];
			break;
			
		default:
			break;
	}
	
	return noErr;
}

#pragma mark - Properties

- (void)setPlayPauseCombo:(KeyCombo)playPauseCombo
{
	if(mPlayPauseCombo.code != -1)
	{
		UnregisterEventHotKey(mPlayPauseHotKeyRef);
		bzero(mPlayPauseHotKeyRef, sizeof(mPlayPauseHotKeyRef));
	}
	
	mPlayPauseCombo = playPauseCombo;
	
	if(playPauseCombo.code != -1)
	{
		EventHotKeyID hotKeyID = {
			.signature = 'plps',
			.id = 1,
		};
		OSStatus error = RegisterEventHotKey(playPauseCombo.code, 
											 SRCocoaToCarbonFlags(playPauseCombo.flags), 
											 hotKeyID, 
											 GetApplicationEventTarget(), 
											 0, 
											 &mPlayPauseHotKeyRef);
		NSAssert((error == noErr), @"Could not register play pause hot key. Error %d", error);
	}
}

- (KeyCombo)playPauseCombo
{
	return mPlayPauseCombo;
}

- (void)setNextTrackCombo:(KeyCombo)nextTrackCombo
{
	if(mNextTrackCombo.code != -1)
	{
		UnregisterEventHotKey(mNextTrackHotKeyRef);
		bzero(mNextTrackHotKeyRef, sizeof(mNextTrackHotKeyRef));
	}
	
	mNextTrackCombo = nextTrackCombo;
	
	if(nextTrackCombo.code != -1)
	{
		EventHotKeyID hotKeyID = {
			.signature = 'nxtk',
			.id = 2,
		};
		OSStatus error = RegisterEventHotKey(nextTrackCombo.code, 
											 SRCocoaToCarbonFlags(nextTrackCombo.flags), 
											 hotKeyID, 
											 GetApplicationEventTarget(), 
											 0, 
											 &mNextTrackHotKeyRef);
		NSAssert((error == noErr), @"Could not register next track hot key. Error %d", error);
	}
}

- (KeyCombo)nextTrackCombo
{
	return mNextTrackCombo;
}

- (void)setPreviousTrackCombo:(KeyCombo)previousTrackCombo
{
	if(mPreviousTrackCombo.code != -1)
	{
		UnregisterEventHotKey(mPreviousTrackHotKeyRef);
		bzero(mPreviousTrackHotKeyRef, sizeof(mPreviousTrackHotKeyRef));
	}
	
	mPreviousTrackCombo = previousTrackCombo;
	
	if(previousTrackCombo.code != -1)
	{
		EventHotKeyID hotKeyID = {
			.signature = 'pvtk',
			.id = 3,
		};
		OSStatus error = RegisterEventHotKey(previousTrackCombo.code, 
											 SRCocoaToCarbonFlags(previousTrackCombo.flags), 
											 hotKeyID, 
											 GetApplicationEventTarget(), 
											 0, 
											 &mPreviousTrackHotKeyRef);
		NSAssert((error == noErr), @"Could not register next track hot key. Error %d", error);
	}
}

- (KeyCombo)previousTrackCombo
{
	return mPreviousTrackCombo;
}

#pragma mark -

@synthesize delegate = mDelegate;

@end
