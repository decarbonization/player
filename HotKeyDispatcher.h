//
//  HotKeyDispatcher.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/24/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "SRCommon.h"

@protocol HotKeyDispatcherDelegate;

RK_EXTERN NSDictionary *KeyComboToDictionary(KeyCombo keyCombo);
RK_EXTERN KeyCombo KeyComboFromDictionary(NSDictionary *dictionary);

#pragma mark -

@interface HotKeyDispatcher : NSObject
{
	EventHotKeyRef mPlayPauseHotKeyRef;
	EventHotKeyRef mNextTrackHotKeyRef;
	EventHotKeyRef mPreviousTrackHotKeyRef;
	
	///Storage for `playPauseCombo`
	KeyCombo mPlayPauseCombo;
	
	///Storage for `nextTrackCombo`
	KeyCombo mNextTrackCombo;
	
	///Storage for `previousTrackCombo`
	KeyCombo mPreviousTrackCombo;
	
	
	///Storage for `delegate`
	id <HotKeyDispatcherDelegate> mDelegate;
}

+ (HotKeyDispatcher *)sharedHotKeyDispatcher;

#pragma mark - Properties

///The key combo to listen for for play pause.
@property (nonatomic) KeyCombo playPauseCombo;

///The key combo to listen for for next track.
@property (nonatomic) KeyCombo nextTrackCombo;

///The key combo to listen for for previous track.
@property (nonatomic) KeyCombo previousTrackCombo;

#pragma mark -

@property (nonatomic) id <HotKeyDispatcherDelegate> delegate;

@end

#pragma mark -

@protocol HotKeyDispatcherDelegate <NSObject>
@required

- (void)hotKeyDispatcherDetectedPlayPause:(HotKeyDispatcher *)sender;

- (void)hotKeyDispatcherDetectedNextTrack:(HotKeyDispatcher *)sender;

- (void)hotKeyDispatcherDetectedPreviousTrack:(HotKeyDispatcher *)sender;

@end
