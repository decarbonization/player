//
//  LyricsViewController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/10/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;
@class Song;

@interface LyricsViewController : NSViewController
{
	///The current song.
	Song *mCurrentSong;
	
	///Whether or not the controller is editing.
	BOOL mIsEditing;
	
	
	///The header view of the buttons.
	IBOutlet NSView *oButtonsHeader;
	
	///The lyrics web view.
	IBOutlet WebView *oLyricsWebView;
}

#pragma mark - Actions

///Saves the lyrics of the receiver.
- (IBAction)save:(id)sender;

@end
