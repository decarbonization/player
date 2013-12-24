//
//  ArtModePane.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 6/6/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "PreferencesPane.h"

@class BackgroundArtworkDisplayView;

@interface ArtModePane : PreferencesPane
{
	///The view used to display a replica of the artwork mode.
	IBOutlet BackgroundArtworkDisplayView *oArtModeModelView;
}

#pragma mark Actions

- (IBAction)restoreDefaultArtModeSize:(id)sender;

@end
