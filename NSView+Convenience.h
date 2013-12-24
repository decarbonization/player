//
//  NSView+Convenience.h
//  Player
//
//  Created by Peter MacWhinnie on 12/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSShadow+EasyCreation.h"
#import "NSBezierPath+MCAdditions.h"

@interface NSView (BKConvenience)

///The first key view of the view.
@property (assign) IBOutlet NSView *firstKeyView;

///The name of the view.
@property (copy) NSString *name;

@end
