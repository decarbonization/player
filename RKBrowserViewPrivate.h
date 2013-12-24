//
//  RKBrowserViewPrivate.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 4/15/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserView.h"

@interface RKBrowserView ()

#pragma mark Handling Keys

- (BOOL)handleSpecialKeyPress:(RKBrowserSpecialKey)key InSubordinateTableView:(NSTableView *)tableView;

@end
