//
//  BrowserTableView.h
//  Pinna
//
//  Created by Peter MacWhinnie on 12/8/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol QueueTableViewDelegate;
@class RKKeyDispatcher;

///The table view subclass used by Pinna for its play queue.
@interface QueueTableView : NSTableView
{
	/** State **/
	
	NSInteger mHoveredUponRow;
	BOOL mHoverButtonIsClicked;
	
	
	/** Properties **/
	NSColor *mAlternateBackgroundColor;
	RKKeyDispatcher *mKeyListener;
}

#pragma mark Properties

///The row currently hovered upon in the browser table view.
///
///Mutating this property causes a redraw of the table view.
@property (nonatomic) NSInteger hoveredUponRow;

@property (nonatomic, assign) id <QueueTableViewDelegate> delegate;

#pragma mark -

///The background color used for alternating rows.
@property (nonatomic, copy) NSColor *alternateBackgroundColor;

///The key listener of the table view.
@property (nonatomic, readonly) RKKeyDispatcher *keyListener;

@end

@protocol QueueTableViewDelegate <NSTableViewDelegate>
@optional

- (NSMenu *)tableView:(NSTableView *)tableView menuForRows:(NSIndexSet *)rows;

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonImageForRow:(NSInteger)row;

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonPressedImageForRow:(NSInteger)row;

- (void)tableView:(NSTableView *)tableView hoverButtonWasClickedAtRow:(NSInteger)row;

@end
