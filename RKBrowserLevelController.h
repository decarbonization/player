//
//  RKBrowserLevelController.h
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 1/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RKBrowserTableView, RKBrowserLevel, RKBrowserView;

@interface RKBrowserLevelController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
	RKBrowserLevel *mBrowserLevel;
	RKBrowserView *mBrowserView;
	
	IBOutlet RKBrowserTableView *oTableView;
	
	IBOutlet NSArrayController *oContentsController;
}

///Initialize the receiver with a specified browser level.
- (id)initWithBrowserLevel:(RKBrowserLevel *)browserLevel browserView:(RKBrowserView *)browserView;

#pragma mark - Properties

///The selection indexes of the controller.
@property (nonatomic, copy) NSIndexSet *selectionIndexes;

///The items selected in the browser level's array controller.
@property (nonatomic, readonly) NSArray *selectedItems;

///The table view of the level controller.
@property (nonatomic, readonly) RKBrowserTableView *tableView;

///The level of the controller.
@property (nonatomic, readonly) RKBrowserLevel *browserLevel;

#pragma mark - Visibility

///Invoked when the receiver is about to become visible in a browser view.
- (void)controllerWillBecomeVisibleInBrowser:(RKBrowserView *)browserView;

///Invoked when the receiver has become visible in a browser view.
- (void)controllerDidBecomeVisibleInBrowser:(RKBrowserView *)browserView;

#pragma mark -

///Invoked when the receiver is about to be removed from a browser view.
- (void)controllerWillBeRemovedFromBrowser:(RKBrowserView *)browserView;

///Invoked when the receiver has been removed from the browser view.
- (void)controllerWasRemovedFromBrowser:(RKBrowserView *)browserView;

@end
