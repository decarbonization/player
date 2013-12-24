//
//  RKBrowserLevel.m
//  NewBrowser
//
//  Created by Kevin MacWhinnie on 1/31/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKBrowserLevel.h"
#import "RKBrowserLevelInternal.h"
#import "RKBrowserView.h"
#import "RKBrowserLevelController.h"

@implementation RKBrowserLevel

+ (NSMutableAttributedString *)formatBrowserTextForDisplay:(NSString *)text isSelected:(BOOL)isSelected dividerString:(NSString *)divider
{
	//In the display string of the songs table view, the song title and the rest of the song
	//information is separated by a "\n". We divide by that when applying styling.
	NSMutableAttributedString *displayString = [[NSMutableAttributedString alloc] initWithString:text];
	NSUInteger dividingPoint = [[displayString string] rangeOfString:divider].location;
	
	if(dividingPoint == NSNotFound)
		dividingPoint = [text length];
	
	[displayString addAttributes:@{NSFontAttributeName: [NSFont boldSystemFontOfSize:12.0]}
						   range:NSMakeRange(0, dividingPoint)];
	
	if(isSelected)
	{
		[displayString addAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:11.0]}
							   range:NSMakeRange(dividingPoint, [displayString length] - dividingPoint)];
		
		[displayString addAttributes:@{NSForegroundColorAttributeName: [NSColor whiteColor], NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:0.0 alpha:0.6], 1.5, NSMakeSize(0.0, -1.0))}
							   range:NSMakeRange(0, [displayString length])];
	}
	else
	{
		[displayString addAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:11.0], NSForegroundColorAttributeName: [NSColor colorWithDeviceWhite:0.5 alpha:1.0], NSShadowAttributeName: RKShadowMake([NSColor colorWithDeviceWhite:1.0 alpha:0.45], 0.0, NSMakeSize(0.0, -1.0))}
							   range:NSMakeRange(dividingPoint, [displayString length] - dividingPoint)];
	}
	
	return displayString;
}

#pragma mark - Properties

@synthesize parentBrowser = mParentBrowser;

#pragma mark -

- (NSString *)title
{
	return @"Untitled";
}

- (NSArray *)contents
{
	[NSException raise:NSInternalInconsistencyException 
				format:@"Abstract implementation of %s invoked.", __PRETTY_FUNCTION__];
	
	return nil;
}

- (void)setSelectedItemIndexes:(NSIndexSet *)selectedItemIndexes
{
	mSelectedItemIndexes = [selectedItemIndexes copy];
	
	mController.selectionIndexes = selectedItemIndexes;
}

- (NSIndexSet *)selectedItemIndexes
{
	if(mController)
		return mController.selectionIndexes;
	
	return mSelectedItemIndexes;
}

- (NSArray *)selectedItems
{
	return mController.selectedItems;
}

@synthesize scrollPoint = mScrollPoint;

#pragma mark -

@synthesize filterPredicate = mFilterPredicate;
@synthesize searchString = mSearchString;

#pragma mark -

- (BOOL)allowsMultipleSelection
{
	return NO;
}

- (NSCell *)rowCellPrototype
{
	return nil;
}

- (CGFloat)rowHeight
{
	return 20.0;
}

- (NSArray *)dragTypes
{
	return [NSArray array];
}

- (BOOL)isValid
{
	return YES;
}

#pragma mark -

- (NSImage *)hoverButtonImageForItem:(id)item
{
	return nil;
}

- (NSImage *)hoverButtonPressedImageForItem:(id)item
{
	return [self hoverButtonImageForItem:nil];
}

#pragma mark - Internal

@synthesize cachedNextLevel = mCachedNextLevel;
@synthesize cachedPreviousLevel = mCachedPreviousLevel;

- (RKBrowserLevel *)deepestCachedLevel
{
	RKBrowserLevel *currentLevel = self;
	while (currentLevel.cachedNextLevel != nil && currentLevel.isValid)
	{
		currentLevel = currentLevel.cachedNextLevel;
	}
	
	return currentLevel;
}

- (RKBrowserLevel *)shallowestLevel
{
	RKBrowserLevel *currentLevel = self;
	while (currentLevel.cachedPreviousLevel != nil && currentLevel.isValid)
	{
		currentLevel = currentLevel.cachedPreviousLevel;
	}
	
	return currentLevel;
}

#pragma mark -

@synthesize controller = mController;

#pragma mark - Visibility

- (void)levelWillBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	[self willChangeValueForKey:@"parentBrowser"];
	mParentBrowser = browserView;
	[self didChangeValueForKey:@"parentBrowser"];
}

- (void)levelDidBecomeVisibleInBrowser:(RKBrowserView *)browserView
{
	
}

#pragma mark -

- (void)levelWillBeRemovedFromBrowser:(RKBrowserView *)browserView
{
	
}

- (void)levelWasRemovedFromBrowser:(RKBrowserView *)browserView
{
	[self willChangeValueForKey:@"parentBrowser"];
	mParentBrowser = nil;
	[self didChangeValueForKey:@"parentBrowser"];
}

#pragma mark - Displaying Items

- (void)levelRowCell:(id)cell willBeDisplayedForItem:(id)item atRow:(NSUInteger)index
{
	NSLog(@"Non-overriden implementation of %s invoked.", __PRETTY_FUNCTION__);
}

- (BOOL)levelRowShouldEditItem:(id)item atRow:(NSUInteger)index
{
	return NO;
}

- (void)levelRowDidSetValue:(id)value forItem:(id)item atRow:(NSUInteger)index
{
	NSLog(@"Non-overriden implementation of %s invoked.", __PRETTY_FUNCTION__);
}

#pragma mark -

- (NSMenu *)contextualMenuForItems:(NSArray *)items
{
	return nil;
}

#pragma mark - Drag and Drop

- (BOOL)writeLevelItems:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard
{
	return NO;
}

- (NSDragOperation)validateDropFromPasteboard:(NSPasteboard *)pasteboard onItem:(id)item withDropTargetUpdater:(RKBrowserDropTargetUpdaterBlock)updateDropTarget
{
	return NSDragOperationNone;
}

- (BOOL)acceptDropFromPasteboard:(NSPasteboard *)pasteboard onItem:(id)item
{
	return NO;
}

#pragma mark - Child Levels

- (BOOL)isChildLevelAvailableForItem:(id)item
{
	return NO;
}

- (RKBrowserLevel *)childBrowserLevelForItem:(id)item
{
	return nil;
}

#pragma mark -

- (void)handleNonLeafSelectionForItem:(id)item
{
	[self.parentBrowser.delegate browserView:self.parentBrowser nonLeafItem:item wasDoubleClickedInLevel:self];
}

#pragma mark - Removal

- (BOOL)deleteItems:(NSArray *)items
{
    return NO;
}

#pragma mark - Hover Button

- (void)handleHoverButtonClickForItem:(id)item
{
	[self.parentBrowser.delegate browserView:self.parentBrowser hoverButtonForItem:item wasClickedInLevel:self];
}

#pragma mark - Infinite Scrolling

- (void)levelDidScrollToEndOfContents
{
	
}

@end
