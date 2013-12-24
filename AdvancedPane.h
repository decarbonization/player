//
//  LibraryPane.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/7/13.
//
//

#import "PreferencesPane.h"

@class Library;

///The AdvancedPane class is responsible for representing Advanced preferences in Pinna.
@interface AdvancedPane : PreferencesPane
{
    Library *mLibrary;
}

#pragma mark Actions

///Causes the receiver to tell the shared Library to use its default location.
- (IBAction)useDefaultLibraryLocation:(id)sender;

///Causes the receiver to run an open panel for the user to select a new
///library location, and then subsequently telling the shread Library to use it.
- (IBAction)changeLibraryLocation:(id)sender;

@end
