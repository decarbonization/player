//
//  RKBrowserLevel.h
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 1/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKBrowserIconTextFieldCell.h"

@class RKBrowserView, RKBrowserLevelController;

enum {
	kRKBrowserDropOperationDropOn = NSTableViewDropOn, 
	kRKBrowserDropOperationDropAbove = NSTableViewDropAbove
};
typedef NSTableViewDropOperation RKBrowserDropOperation;

typedef void(^RKBrowserDropTargetUpdaterBlock)(id targetItem, RKBrowserDropOperation operation);

///The concrete object used to provide content to RKBrowserView instances.
@interface RKBrowserLevel : NSObject
{
@private
	
	///Set by the RKBrowserView when the level is added to its hierarchy.
	RKBrowserView *mParentBrowser;
	
	///Backing for `selectedItemIndexes`
	NSIndexSet *mSelectedItemIndexes;
	
	///Backing for `scrollPoint`
	NSPoint mScrollPoint;
	
	
	///Backing for `filterPredicate`
	NSPredicate *mFilterPredicate;
	
	///Backing for `searchString`
	NSString *mSearchString;
	
	/** Internal **/
	
	///Storage for `cachedPreviousLevel`
	RKBrowserLevel *mCachedPreviousLevel;
	
	///Storage for `cachedNextLevel`
	RKBrowserLevel *mCachedNextLevel;
	
	///Storage for `controller`
	RKBrowserLevelController *mController;
}

+ (NSMutableAttributedString *)formatBrowserTextForDisplay:(NSString *)text isSelected:(BOOL)isSelected dividerString:(NSString *)divider;

#pragma mark - Properties

///The parent view of the level.
///
///This property is set by the parent browser
///view when a level is added to a browser view.
///This *should not* be overridden by subclasses.
@property (nonatomic, readonly) RKBrowserView *parentBrowser;

#pragma mark -

///The title of the browser level. Must be KVC compliant.
@property (nonatomic, readonly) NSString *title;

///The contents of the browser level. Must be KVC compliant.
///
///This property must be overriden.
@property (nonatomic, readonly) NSArray *contents;

///The selected items of the browser level.
@property (nonatomic, copy) NSIndexSet *selectedItemIndexes;

///The selected items of the level.
///
///This property will correctly take into account
///any filtering of contents done in the presentation
///layer of the RKBrowserView apparatus.
@property (nonatomic, readonly) NSArray *selectedItems;

///The scroll point of the browser level.
@property (nonatomic) NSPoint scrollPoint;

#pragma mark -

///The filter predicate the browser should apply to
///the level's contents before displaying them.
///
///Levels which support searching should modify this
///property when their `searchString` property is mutated.
@property (nonatomic, copy) NSPredicate *filterPredicate;

///The string to search for in the level.
///
///Levels which support searching should mutate their
///`filterPredicate` when this property is changed.
@property (nonatomic, copy) NSString *searchString;

#pragma mark -

///Indicates whether or not a level is valid. This property is
///used when an RKBrowserView has to determine whether or not to
///display a level's children, instead of the RKBrowserLevel itself.
///
///The default implementation of this property always indicates YES.
@property (nonatomic, readonly) BOOL isValid;

///The cell used to display the contents of the browser level's cells.
///
///If this property is not overriden, the browser will use
///its default IconTextFieldCell prototype.
@property (nonatomic, readonly) NSCell *rowCellPrototype;

///The row height of the browser level's items.
///
///The default value is 20.
@property (nonatomic, readonly) CGFloat rowHeight;

///The drag types of the browser level, if any.
@property (nonatomic, readonly) NSArray *dragTypes;

///Whether or not the level supports multiple selection.
///
///The default value is NO.
@property (nonatomic, readonly) BOOL allowsMultipleSelection;

#pragma mark -

///The image to display for the hover button of the browser. Optional.
- (NSImage *)hoverButtonImageForItem:(id)item;

///The image to display for the hover button of the browser when it's pressed. Optional.
- (NSImage *)hoverButtonPressedImageForItem:(id)item;

#pragma mark - Visibility

///Invoked when the receiver is about to become visible in a browser view.
///
///Subclasses *must* invoked super.
- (void)levelWillBecomeVisibleInBrowser:(RKBrowserView *)browserView;

///Invoked when the receiver has become visible in a browser view.
///
///Subclasses *must* invoked super.
- (void)levelDidBecomeVisibleInBrowser:(RKBrowserView *)browserView;

#pragma mark -

///Invoked when the receiver is about to be removed from a browser view.
///
///Subclasses *must* invoked super.
- (void)levelWillBeRemovedFromBrowser:(RKBrowserView *)browserView;

///Invoked when the receiver has been removed from the browser view.
///
///Subclasses *must* invoked super.
- (void)levelWasRemovedFromBrowser:(RKBrowserView *)browserView;

#pragma mark - Displaying Items

///Invoked when the receiver's row view is about to be displayed for a specified item.
///
///This property should be overriden.
- (void)levelRowCell:(RKBrowserIconTextFieldCell *)cell willBeDisplayedForItem:(id)item atRow:(NSUInteger)index;

///Invoked when the browser needs to know whether an item should be edited.
- (BOOL)levelRowShouldEditItem:(id)item atRow:(NSUInteger)index;

///Invoked when the browser set the value of a specified item.
- (void)levelRowDidSetValue:(id)value forItem:(id)item atRow:(NSUInteger)index;

#pragma mark - Contextual Menus

///Invoked when the browser requires a contextual menu for an array of specified items.
- (NSMenu *)contextualMenuForItems:(NSArray *)items;

#pragma mark - Drag and Drop

///Write the specified rows to the specified pasteboard.
///
///YES if a drag operation is to be allowed; NO otherwise.
- (BOOL)writeLevelItems:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard;

///Validate a potential drop operation from a specified pasteboard on a specified item.
///
///You may update the row/style of drop using the specified `dropTargetUpdater` block.
- (NSDragOperation)validateDropFromPasteboard:(NSPasteboard *)pasteboard onItem:(id)item withDropTargetUpdater:(RKBrowserDropTargetUpdaterBlock)updateDropTarget;

///Accept a specified pasteboard dropped on the browser level on a specified item.
///
///YES if the drop was accepted; NO otherwise.
- (BOOL)acceptDropFromPasteboard:(NSPasteboard *)pasteboard onItem:(id)item;

#pragma mark - Child Levels

///Invoked when a parent browser needs to know if a child level
///is available for a specified item contained in the receiver.
- (BOOL)isChildLevelAvailableForItem:(id)item;

///Invoked when the next level for a specified item is required.
///
///This method is invoked when an item is selected.
- (RKBrowserLevel *)childBrowserLevelForItem:(id)item;

#pragma mark -

///Invoked when a parent browser has selected an item
///(I.e. through double click) that does not have a child.
///
///The default implementation of this method invokes `-[RKBrowserViewDelegate browserView:nonLeafItem:wasDoubleClickedInLevel:]`.
- (void)handleNonLeafSelectionForItem:(id)item;

#pragma mark - Removal

///Invoked the user has attempted to delete an item from the browser.
///
/// \result YES to indicate the item could be deleted; NO otherwise.
- (BOOL)deleteItems:(NSArray *)items;

#pragma mark - Hover Button

///Invoked when a hover button has been clicked for a specified item.
- (void)handleHoverButtonClickForItem:(id)item;

#pragma mark - Infinite Scrolling

///Invoked when the user has scrolled to the end of the contents.
///
///This method should be used to implement infinite scrolling.
- (void)levelDidScrollToEndOfContents;

@end
