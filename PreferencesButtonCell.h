//
//  SimpleWhiteButton.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 1/2/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <AppKit/AppKit.h>

///The PreferencesButtonCell class encapsulates a flat aesthetic
///button suitable for use in the Preferences window in Pinna.
@interface PreferencesButtonCell : NSButtonCell

///Whether or not the cell has square corners.
@property (nonatomic) BOOL hasSquareCorners;

@end
