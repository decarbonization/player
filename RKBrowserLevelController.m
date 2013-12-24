//
//  RKBrowserLevelController.m
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 1/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserLevelController.h"
#import "RKBrowserView.h"
#import "RKBrowserLevel.h"
#import "RKBrowserTableView.h"
#import "RKBrowserScrollView.h"

@implementation RKBrowserLevelController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithBrowserLevel:(RKBrowserLevel *)browserLevel browserView:(RKBrowserView *)browserView
{
	NSParameterAssert(browserLevel);
	
	if((self = [super initWithNibName:@"RKBrowserLevelController" 
							   bundle:[NSBundle bundleForClass:[RKBrowserLevelController class]]]))
	{
		mBrowserLevel = browserLevel;
		mBrowserView = browserView;
	}
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	oTableView.browserView = mBrowserView;
	
	[oTableView selectRowIndexes:mBrowserLevel.selectedItemIndexes byExtendingSelection:YES];
	[oTableView.enclosingScrollView.contentView scrollToPoint:mBrowserLevel.scrollPoint];
	[oTableView registerForDraggedTypes:mBrowserLevel.dragTypes];
	
	[oTableView setAllowsMultipleSelection:mBrowserLevel.allowsMultipleSelection];
	[oTableView setIntercellSpacing:NSZeroSize];
	[oTableView setRowHeight:mBrowserLevel.rowHeight];
	
	[oTableView setTarget:self];
	[oTableView setDoubleAction:@selector(tableViewWasDoubleClicked:)];
	
	[oContentsController setSelectionIndexes:mBrowserLevel.selectedItemIndexes];
	[oContentsController bind:NSFilterPredicateBinding 
					 toObject:mBrowserLevel 
				  withKeyPath:@"filterPredicate" 
					  options:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(browserScrollViewDidScrollToBottom:) 
												 name:RKBrowserScrollViewDidScrollToBottomNotification 
											   object:[oTableView enclosingScrollView]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if((object == mBrowserLevel) && [keyPath isEqualToString:@"selectedItemIndexes"])
	{
		NSIndexSet *selectedIndexes = mBrowserLevel.selectedItemIndexes;
		//This redundant check is to prevent infinite loops. See `tableViewSelectionDidChange:`
		if(![[oTableView selectedRowIndexes] isEqualToIndexSet:selectedIndexes])
			[oTableView selectRowIndexes:selectedIndexes byExtendingSelection:NO];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingSelectionIndexes
{
	return [NSSet setWithObjects:@"oContentsController.selectionIndexes", nil];
}

- (void)setSelectionIndexes:(NSIndexSet *)selectionIndexes
{
	[oTableView selectRowIndexes:selectionIndexes ?: [NSIndexSet indexSet] byExtendingSelection:NO];
}

- (NSIndexSet *)selectionIndexes
{
	return [oTableView selectedRowIndexes];
}

- (NSArray *)selectedItems
{
	return [oContentsController selectedObjects];
}

@synthesize tableView = oTableView;
@synthesize browserLevel = mBrowserLevel;

#pragma mark - Visibility

- (void)controllerWillBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	[mBrowserLevel levelWillBecomeVisibleInBrowser:browserView];
	oTableView.hoveredUponRow = -1;
}

- (void)controllerDidBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	[mBrowserLevel levelDidBecomeVisibleInBrowser:browserView];
}

#pragma mark -

- (void)controllerWillBeRemovedFromBrowser:(RKBrowserView *)browserView
{
	[mBrowserLevel levelWillBeRemovedFromBrowser:browserView];
	
	mBrowserLevel.scrollPoint = oTableView.enclosingScrollView.contentView.bounds.origin;
}

- (void)controllerWasRemovedFromBrowser:(RKBrowserView *)browserView
{
	[mBrowserLevel levelWasRemovedFromBrowser:browserView];
	oTableView.hoveredUponRow = -1;
}

#pragma mark - Infinite Scrolling

- (void)browserScrollViewDidScrollToBottom:(NSNotification *)notification
{
	[mBrowserLevel levelDidScrollToEndOfContents];
}

#pragma mark - Table View Stuff

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	mBrowserLevel.selectedItemIndexes = [oTableView selectedRowIndexes];
}

- (void)tableViewWasDoubleClicked:(NSTableView *)tableView
{
	if([tableView clickedRow] == -1)
		return;
	
	NSUInteger row = [tableView clickedRow];
	id item = [[oContentsController arrangedObjects] objectAtIndex:row];
	
	if([mBrowserLevel isChildLevelAvailableForItem:item])
	{
		RKBrowserLevel *nextLevel = [mBrowserLevel childBrowserLevelForItem:item];
		[mBrowserView moveIntoBrowserLevel:nextLevel];
	}
	else
	{
		[mBrowserLevel handleNonLeafSelectionForItem:item];
	}
}

- (NSMenu *)tableView:(NSTableView *)tableView menuForRows:(NSIndexSet *)rows
{
	NSArray *items = [[oContentsController arrangedObjects] objectsAtIndexes:rows];
	return [mBrowserLevel contextualMenuForItems:items];
}

#pragma mark -

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSCell *possibleCell = mBrowserLevel.rowCellPrototype;
	if(possibleCell)
		return possibleCell;
	
	return [tableColumn dataCellForRow:row];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id item = [[oContentsController arrangedObjects] objectAtIndex:row];
	[mBrowserLevel levelRowCell:cell willBeDisplayedForItem:item atRow:row];
	
	if([[tableView selectedRowIndexes] containsIndex:row])
		[cell setTextColor:[NSColor whiteColor]];
	else
		[cell setTextColor:[NSColor textColor]];
}

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonImageForRow:(NSInteger)row
{
	id item = [[oContentsController arrangedObjects] objectAtIndex:row];
	return [mBrowserLevel hoverButtonImageForItem:item];
}

- (NSImage *)tableView:(NSTableView *)tableView hoverButtonPressedImageForRow:(NSInteger)row
{
	id item = [[oContentsController arrangedObjects] objectAtIndex:row];
	return [mBrowserLevel hoverButtonPressedImageForItem:item];
}

- (void)tableView:(NSTableView *)tableView hoverButtonWasClickedAtRow:(NSInteger)row
{
	id item = [[oContentsController arrangedObjects] objectAtIndex:row];
	[mBrowserLevel handleHoverButtonClickForItem:item];
}

#pragma mark -

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id item = [[oContentsController arrangedObjects] objectAtIndex:row];
	return [mBrowserLevel levelRowShouldEditItem:item atRow:row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	id item = [[oContentsController arrangedObjects] objectAtIndex:row];
	[mBrowserLevel levelRowDidSetValue:object forItem:item atRow:row];
}

#pragma mark - Drag & Drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard
{
	NSArray *items = [[oContentsController arrangedObjects] objectsAtIndexes:rowIndexes];
	return [mBrowserLevel writeLevelItems:items toPasteboard:pasteboard];
}

#pragma mark -

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	RKBrowserDropTargetUpdaterBlock dropTargetUpdater = ^(id dropItem, RKBrowserDropOperation operation) {
		if(dropItem == nil)
			[tableView setDropRow:-1 dropOperation:operation];
		else
			[tableView setDropRow:[mBrowserLevel.contents indexOfObject:dropItem] dropOperation:operation];
	};
	
	id item = (row == -1 || row >= [mBrowserLevel.contents count])? nil : [[oContentsController arrangedObjects] objectAtIndex:row];
	NSPasteboard *pasteboard = [info draggingPasteboard];
	
	return [mBrowserLevel validateDropFromPasteboard:pasteboard onItem:item withDropTargetUpdater:dropTargetUpdater];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pasteboard = [info draggingPasteboard];
	id item = (row == -1 || row >= [mBrowserLevel.contents count])? nil : [[oContentsController arrangedObjects] objectAtIndex:row];
	return [mBrowserLevel acceptDropFromPasteboard:pasteboard onItem:item];
}

@end
