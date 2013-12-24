//
//  RKBrowserTableView.h
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 1/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <AppKit/AppKit.h>

@class RKBrowserView;

@protocol RKBrowserTableViewDelegate;

@interface RKBrowserTableView : NSTableView
{
	RKBrowserView *mBrowserView;
	
	NSInteger mHoveredUponRow;
	BOOL mHoverButtonIsClicked;
	
	NSColor *mAlternateBackgroundColor;
}

///The browser view of the table view.
@property (nonatomic) RKBrowserView *browserView;

@property (nonatomic) id <RKBrowserTableViewDelegate> delegate;

///The row currently hovered upon in the browser table view.
///
///Mutating this property causes a redraw of the table view.
@property (nonatomic) NSInteger hoveredUponRow;

///The alternate background color of the browser table view.
@property (nonatomic) NSColor *alternateBackgroundColor;

@end

@protocol RKBrowserTableViewDelegate <NSTableViewDelegate>
@required

- (NSMenu *)tableView:(NSTableView *)tableView menuForRows:(NSIndexSet *)rows;

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonImageForRow:(NSInteger)row;

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonPressedImageForRow:(NSInteger)row;

- (void)tableView:(NSTableView *)tableView hoverButtonWasClickedAtRow:(NSInteger)row;

@end