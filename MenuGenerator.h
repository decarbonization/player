//
//  ContextualMenuGenerator.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 8/22/12.
//
//

#import <Foundation/Foundation.h>

@class Library;

///The MenuGenerator class is responsible for generating contextual
///and share menus for the Pinna application.
@interface MenuGenerator : NSObject
{
	Library *library;
}

#pragma mark Lifecycle

///Returns the shared menu generator, creating it if it doesn't exist.
+ (MenuGenerator *)sharedGenerator;

#pragma mark - Menu Generation

///Returns a fully configured contextual menu for an array of library items.
- (NSMenu *)contextualMenuForLibraryItems:(NSArray *)items;

@end
