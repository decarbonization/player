//
//  BrowserTableView.m
//  Pinna
//
//  Created by Peter MacWhinnie on 12/8/10.
//  Copyright 2010 Roundabout Software, LLC. All rights reserved.
//

#import "QueueTableView.h"
#import "RKBrowserIconTextFieldCell.h"
#import "RKKeyDispatcher.h"

static NSGradient *SelectionGradientActive = nil,
				  *SelectionGradientInactive = nil;

@implementation QueueTableView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)initialize
{
	SelectionGradientActive = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.29 green:0.68 blue:0.91 alpha:1.00] 
															endingColor:[NSColor colorWithCalibratedRed:0.00 green:0.51 blue:0.84 alpha:1.00]];
	
	SelectionGradientInactive = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.76 green:0.75 blue:0.76 alpha:1.00] 
															  endingColor:[NSColor colorWithCalibratedRed:0.61 green:0.61 blue:0.61 alpha:1.00]];
	
	[super initialize];
}

- (void)awakeFromNib
{
	[[self window] setAcceptsMouseMovedEvents:YES];
	
	mHoveredUponRow = -1;
	
	[self.keyListener setHandlerForKeyCode:/*escape*/53 block:^(NSUInteger modifierFlags) {
		[self deselectAll:nil];
		return YES;
	}];
}

#pragma mark - Hover

@synthesize hoveredUponRow = mHoveredUponRow;
- (void)setHoveredUponRow:(NSInteger)hoveredUponRow
{
	if(mHoveredUponRow == hoveredUponRow)
		return;
	
	if(mHoveredUponRow != -1)
		[self setNeedsDisplayInRect:[self rectOfRow:mHoveredUponRow]];
	
	mHoveredUponRow = hoveredUponRow;
	
	if(mHoveredUponRow != -1)
		[self setNeedsDisplayInRect:[self rectOfRow:mHoveredUponRow]];
}

- (NSCell *)preparedCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	id cell = [super preparedCellAtColumn:column row:row];
	if([cell isKindOfClass:[RKBrowserIconTextFieldCell class]])
	{
		if(mHoveredUponRow != -1 && row == mHoveredUponRow)
		{
			if(mHoverButtonIsClicked)
				[cell setButtonImage:[self.delegate tableView:self hoverButtonPressedImageForRow:row]];
			else
				[cell setButtonImage:[self.delegate tableView:self hoverButtonImageForRow:row]];
		}
		else
		{
			[cell setButtonImage:nil];
		}
	}
	
	return cell;
}

#pragma mark - Maintaining Highlight Styling

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSWindowDidBecomeKeyNotification 
												  object:[self window]];
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSWindowDidResignKeyNotification 
												  object:[self window]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(windowDidChangeKey:) 
												 name:NSWindowDidBecomeKeyNotification 
											   object:newWindow];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(windowDidChangeKey:) 
												 name:NSWindowDidResignKeyNotification 
											   object:newWindow];
}

- (void)windowDidChangeKey:(NSNotification *)notification
{
	__block NSRect selectedRowArea = NSZeroRect;
	[[self selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
		selectedRowArea = NSUnionRect(selectedRowArea, [self rectOfRow:row]);
	}];
	[self setNeedsDisplayInRect:selectedRowArea];
}

- (BOOL)becomeFirstResponder
{
	BOOL becameFirstResponder = [super becomeFirstResponder];
	
	__block NSRect selectedRowArea = NSZeroRect;
	[[self selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
		selectedRowArea = NSUnionRect(selectedRowArea, [self rectOfRow:row]);
	}];
	[self setNeedsDisplayInRect:selectedRowArea];
	
	return becameFirstResponder;
}

- (BOOL)resignFirstResponder
{
	BOOL resignedFirstResponder = [super resignFirstResponder];
	
	__block NSRect selectedRowArea = NSZeroRect;
	[[self selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
		selectedRowArea = NSUnionRect(selectedRowArea, [self rectOfRow:row]);
	}];
	[self setNeedsDisplayInRect:selectedRowArea];
	
	return resignedFirstResponder;
}

#pragma mark - Properties

@dynamic delegate;

- (void)setAlternateBackgroundColor:(NSColor *)alternateBackgroundColor
{
	mAlternateBackgroundColor = [alternateBackgroundColor copy];
	[self setNeedsDisplay:YES];
}

- (NSColor *)alternateBackgroundColor
{
	if(!mAlternateBackgroundColor) mAlternateBackgroundColor = [NSColor colorWithDeviceWhite:0.0 alpha:0.02];
	
	return [mAlternateBackgroundColor copy];
}

- (RKKeyDispatcher *)keyListener
{
	if(!mKeyListener)
		mKeyListener = [RKKeyDispatcher new];
	
	return mKeyListener;
}

#pragma mark - Selection

//TODO: Remember non-private way to do this:
- (id)_highlightColorForCell:(NSCell *)cell
{
	return nil;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if(![self usesAlternatingRowBackgroundColors])
	{
		[super drawBackgroundInClipRect:clipRect];
	}
}

- (void)highlightSelectionInClipRect:(NSRect)rect
{
	if([self usesAlternatingRowBackgroundColors])
	{
		[[self backgroundColor] set];
		[NSBezierPath fillRect:rect];
		
		CGFloat rowHeight = [self rowHeight] + [self intercellSpacing].height;
		NSRect visibleRect = [self visibleRect];
		NSRect highlightRect;
		highlightRect.origin = NSMakePoint(NSMinX(visibleRect), round(NSMinY(rect) / rowHeight) * rowHeight);
		highlightRect.size = NSMakeSize(NSWidth(visibleRect), rowHeight - [self intercellSpacing].height);
		
		while (NSMinY(highlightRect) < NSMaxY(rect))
		{
			NSRect clippedHighlightRect = NSIntersectionRect(highlightRect, rect);
			NSUInteger row = round((NSMinY(highlightRect) + rowHeight / 2.0) / rowHeight);
			if((row % 2) == 0)
			{
				[self.alternateBackgroundColor set];
				[NSBezierPath fillRect:clippedHighlightRect];
			}
			highlightRect.origin.y += rowHeight;
		}
	}
	
	BOOL isWindowKey = [[self window] isKeyWindow];
	BOOL isFirstResponder = ([[self window] firstResponder] == self);
	[[self selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
		NSRect rowArea = [self rectOfRow:row];
		if(isWindowKey && isFirstResponder)
			[SelectionGradientActive drawInRect:rowArea angle:90.0];
		else
			[SelectionGradientInactive drawInRect:rowArea angle:90.0];
		
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.15] set];
		[NSBezierPath fillRect:NSMakeRect(NSMinX(rowArea), NSMinY(rowArea), 
										  NSWidth(rowArea), 1.0)];
		
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.20] set];
		[NSBezierPath fillRect:NSMakeRect(NSMinX(rowArea), NSMinY(rowArea) + 1.0, 
										  NSWidth(rowArea), 1.0)];
		
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.1] set];
		[NSBezierPath fillRect:NSMakeRect(NSMinX(rowArea), NSMaxY(rowArea) - 1.0,
										  NSWidth(rowArea), 1.0)];
	}];
}

#pragma mark - Events

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	if([[self delegate] respondsToSelector:@selector(tableView:menuForRows:)])
	{
		NSPoint rowPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		NSInteger rowIndex = [self rowAtPoint:rowPoint];
		if(rowIndex == -1)
		{
			[self deselectAll:nil];
		}
		else
		{
			NSIndexSet *existingSelection = [self selectedRowIndexes];
			if([existingSelection count] <= 1 || ![existingSelection containsIndex:rowIndex])
			{
				[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
			}
		}
		
		return [[self delegate] tableView:self menuForRows:[self selectedRowIndexes]];
	}
	
	return [super menuForEvent:event];
}

#pragma mark -

- (void)mouseUp:(NSEvent *)event
{
	NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:mouseLocation];
	if(mHoveredUponRow != -1 && row == mHoveredUponRow)
	{
		NSImage *hoverButtonImage = [self.delegate tableView:self hoverButtonImageForRow:row];
		CGFloat widthOfRowExcludingButton = NSWidth([self rectOfRow:row]) - [hoverButtonImage size].width;
		if(mouseLocation.x > widthOfRowExcludingButton)
		{
			mHoverButtonIsClicked = NO;
			[self setNeedsDisplayInRect:[self rectOfRow:row]];
			
			[self.delegate tableView:self hoverButtonWasClickedAtRow:row];
			
			return;
		}
	}
	
	[super mouseUp:event];
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:mouseLocation];
	if(mHoveredUponRow != -1 && row == mHoveredUponRow)
	{
		NSImage *hoverButtonImage = [self.delegate tableView:self hoverButtonImageForRow:row];
		CGFloat widthOfRowExcludingButton = NSWidth([self rectOfRow:row]) - [hoverButtonImage size].width;
		if(mouseLocation.x > widthOfRowExcludingButton)
		{
			mHoverButtonIsClicked = YES;
			[self setNeedsDisplayInRect:[self rectOfRow:row]];
			
			return;
		}
	}
	
	[super mouseDown:event];
}

- (void)keyDown:(NSEvent *)event
{
	if([mKeyListener dispatchKey:[event keyCode] withModifiers:[event modifierFlags]])
		return;
	
	[super keyDown:event];
}

@end
