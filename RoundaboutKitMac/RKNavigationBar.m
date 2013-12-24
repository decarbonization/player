//
//  RKNavigationBar.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKNavigationBar.h"

@implementation RKNavigationBar {
    RKNavigationItem *_visibleNavigationItem;
    NSMutableArray *_navigationItems;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if((self = [super initWithFrame:frameRect])) {
        _navigationItems = [NSMutableArray array];
        
        self.foregroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.76 green:0.76 blue:0.76 alpha:0.85]
                                                                endingColor:[NSColor colorWithCalibratedRed:0.91 green:0.91 blue:0.91 alpha:0.99]];
        self.backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.94 green:0.94 blue:0.94 alpha:0.89]
                                                                endingColor:[NSColor colorWithCalibratedRed:0.99 green:0.99 blue:0.99 alpha:0.99]];
        
        self.image = [NSImage imageNamed:@"WindowTexture"];
        self.shouldTileImage = YES;
        self.shouldDrawImageAboveGradient = NO;
    }
    
    return self;
}

#pragma mark - Properties

- (NSArray *)navigationItems
{
    return [_navigationItems copy];
}

- (RKNavigationItem *)topNavigationItem
{
    return _navigationItems[0];
}

- (RKNavigationItem *)visibleNavigationItem
{
    return [_navigationItems lastObject];
}

#pragma mark - Pushing and Popping Items

- (void)pushNavigationItem:(RKNavigationItem *)navigationItem animated:(BOOL)animated
{
    NSParameterAssert(navigationItem);
    
    NSAssert(![_navigationItems containsObject:navigationItem],
             @"Cannot push navigation item %@ more than once", navigationItem);
    
    [_navigationItems addObject:navigationItem];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromRight:navigationItem];
    else
        [self replaceVisibleNavigationItemWith:navigationItem];
}

- (void)popNavigationItemAnimated:(BOOL)animated
{
    if([_navigationItems count] == 1)
        return;
    
    [_navigationItems removeLastObject];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromLeft:self.visibleNavigationItem];
    else
        [self replaceVisibleNavigationItemWith:self.visibleNavigationItem];
}

- (void)popToNavigationItem:(RKNavigationItem *)navigationItem animated:(BOOL)animated
{
    NSParameterAssert(navigationItem);
    
    NSInteger indexOfNavigationItem = [_navigationItems indexOfObject:navigationItem];
    NSAssert(indexOfNavigationItem != NSNotFound,
             @"Cannot pop from navigation item %@ that isn't in stack", navigationItem);
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexOfNavigationItem + 1, _navigationItems.count - (indexOfNavigationItem + 1))];
    [_navigationItems removeObjectsAtIndexes:indexesToRemove];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromLeft:navigationItem];
    else
        [self replaceVisibleNavigationItemWith:navigationItem];
}

- (void)popToRootNavigationItemAnimated:(BOOL)animated
{
    if([self.navigationItems count] == 1)
        return;
    
    RKNavigationItem *topNavigationItem = self.topNavigationItem;
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _navigationItems.count - 1)];
    [_navigationItems removeObjectsAtIndexes:indexesToRemove];
    
    if(animated)
        [self replaceVisibleNavigationItemPushingFromLeft:topNavigationItem];
    else
        [self replaceVisibleNavigationItemWith:topNavigationItem];
}

#pragma mark - Changing Frame Views

- (void)replaceVisibleNavigationItemWith:(RKNavigationItem *)view
{
    if(_visibleNavigationItem) {
        [_visibleNavigationItem removeFromSuperviewWithoutNeedingDisplay];
        _visibleNavigationItem = nil;
    }
    
    _visibleNavigationItem = view;
    
    if(_visibleNavigationItem) {
        [_visibleNavigationItem setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_visibleNavigationItem setFrame:self.bounds];
        [self addSubview:_visibleNavigationItem];
    }
}

- (void)replaceVisibleNavigationItemPushingFromLeft:(RKNavigationItem *)newView
{
    if(!_visibleNavigationItem) {
        [self replaceVisibleNavigationItemWith:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.bounds;
    initialNewViewFrame.origin.x = -NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self addSubview:newView];
    
    NSView *oldView = _visibleNavigationItem;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = NSMaxX(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleNavigationItem = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setAlphaValue:0.0];
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
        [oldView setAlphaValue:1.0];
    }];
}

- (void)replaceVisibleNavigationItemPushingFromRight:(RKNavigationItem *)newView
{
    if(!_visibleNavigationItem) {
        [self replaceVisibleNavigationItemWith:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.bounds;
    initialNewViewFrame.origin.x = NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self addSubview:newView];
    
    NSView *oldView = _visibleNavigationItem;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = -NSWidth(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleNavigationItem = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setAlphaValue:0.0];
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
        [oldView setAlphaValue:1.0];
    }];
}

@end
