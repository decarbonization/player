//
//  HotKeysPane.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 7/7/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "PreferencesPane.h"

@class SRRecorderControl;

@interface HotKeysPane : PreferencesPane
{
	IBOutlet SRRecorderControl *oPlayPauseRecorder;
	IBOutlet SRRecorderControl *oNextTrackRecorder;
	IBOutlet SRRecorderControl *oPreviousTrackRecorder;
}

#pragma mark Actions

- (IBAction)listensForMediaKeysChanged:(NSButton *)sender;

@end
