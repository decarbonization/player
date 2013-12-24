//
//  PlayKeysAppDelegate.h
//  PlayKeys
//
//  Created by Kevin MacWhinnie on 11/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MediaKeyEventTap.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, MediaKeyEventTapDelegate>

@end
