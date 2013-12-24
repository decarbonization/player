//
//  RKNavigationController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKNavigationController.h"
#import "RKViewController_Private.h"
#import "RKBarButton.h"

@interface RKNavigationController ()

///The view that holds the contents of the controller's children.
@property (nonatomic) NSView *contentView;

@end

@implementation RKNavigationController

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithRootViewController:(RKViewController *)viewController
{
    if((self = [super init])) {
        _viewControllers = [NSMutableArray array];
        
        self.view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 320.0, 500.0)];
        self.contentView = [[NSView alloc] initWithFrame:self.view.frame];
        self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self.view addSubview:self.contentView];
        
        _navigationBar = [[RKNavigationBar alloc] initWithFrame:NSMakeRect(0.0, 0.0, 320.0, 40.0)];
        _navigationBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [self.view addSubview:_navigationBar];
        
        [self layoutViews];
        
        if(viewController)
            [self pushViewController:viewController animated:NO];
    }
    
    return self;
}

- (void)layoutViews
{
    NSRect contentArea = self.view.frame;
    contentArea.origin = NSZeroPoint;
    
    NSRect navigationBarFrame = self.navigationBar.frame;
    navigationBarFrame.size.width = NSWidth(contentArea);
    navigationBarFrame.origin.x = 0.0;
    navigationBarFrame.origin.y = NSHeight(contentArea) - NSHeight(navigationBarFrame);
    self.navigationBar.frame = navigationBarFrame;
    
    NSRect contentViewFrame = self.contentView.frame;
    if(self.navigationBarHidden) {
        contentViewFrame.origin = NSZeroPoint;
        contentViewFrame.size = contentArea.size;
    } else {
        contentViewFrame.origin = NSZeroPoint;
        contentViewFrame.size.width = NSWidth(contentArea);
        contentViewFrame.size.height = NSHeight(contentArea) - NSHeight(self.navigationBar.frame);
    }
    
    self.contentView.frame = contentViewFrame;
}

#pragma mark - Stack

- (RKViewController *)topViewController
{
    return self.viewControllers[0];
}

- (RKViewController *)visibleViewController
{
    return [self.viewControllers lastObject];
}

@synthesize viewControllers = _viewControllers;

#pragma mark - Navigation Bar

@synthesize navigationBar = _navigationBar;

- (void)setNavigationBarHidden:(BOOL)navigationBarHidden
{
    self.navigationBar.hidden = navigationBarHidden;
    [self layoutViews];
}

- (BOOL)isNavigationBarHidden
{
    return self.navigationBar.isHidden;
}

#pragma mark - Pushing and Popping Stack Items

- (void)pushViewController:(RKViewController *)viewController animated:(BOOL)animated
{
    NSParameterAssert(viewController);
    
    NSAssert((viewController.navigationController == nil),
             @"Cannot push view controller %@ into multiple navigation controllers.", viewController);
    NSAssert((viewController.view.superview == nil),
              @"View controller %@ cannot be hosted in multiple places.", viewController);
    
    [_viewControllers addObject:viewController];
    viewController.navigationController = self;
    
    [self.visibleViewController viewWillDisappear:animated];
    [viewController viewWillAppear:animated];
    if(animated) {
        [self replaceVisibleViewWithViewPushingFromRight:viewController.view completionHandler:^{
            [self.visibleViewController viewDidDisappear:animated];
            [viewController viewDidAppear:animated];
        }];
    } else {
        [self replaceVisibleViewWithView:viewController.view];
        
        [self.visibleViewController viewDidDisappear:animated];
        [viewController viewDidAppear:animated];
    }
    
    if([self.viewControllers count] > 1) {
        NSString *backButtonTitle = [self.viewControllers[self.viewControllers.count - 2] navigationItem].title;
        if([backButtonTitle length] > 15)
            backButtonTitle = @"Back";
        
        RKBarButton *backButton = [[RKBarButton alloc] initWithType:kRKBarButtonTypeBackButton
                                                              title:backButtonTitle
                                                             target:viewController
                                                             action:@selector(popFromNavigationController:)];
        [backButton setKeyEquivalent:@"\E"];
        viewController.navigationItem.leftView = backButton;
    }
    
    [_navigationBar pushNavigationItem:viewController.navigationItem animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    if([self.viewControllers count] == 1)
        return;
    
    RKViewController *previousViewController = self.visibleViewController;
    [_viewControllers removeLastObject];
    previousViewController.navigationController = nil;
    previousViewController.navigationItem.leftView = nil;
    
    [previousViewController viewWillDisappear:animated];
    [self.visibleViewController viewWillAppear:animated];
    if(animated) {
        [self replaceVisibleViewWithViewPushingFromLeft:self.visibleViewController.view completionHandler:^{
            [previousViewController viewDidDisappear:animated];
            [self.visibleViewController viewDidAppear:animated];
        }];
    } else {
        [self replaceVisibleViewWithView:self.visibleViewController.view];
        
        [previousViewController viewDidDisappear:animated];
        [self.visibleViewController viewDidAppear:animated];
    }
    
    [_navigationBar popNavigationItemAnimated:animated];
}

- (void)popToViewController:(RKViewController *)viewController animated:(BOOL)animated
{
    NSUInteger indexOfViewController = [self.viewControllers indexOfObject:viewController];
    NSAssert((indexOfViewController != NSNotFound),
             @"View controller %@ is not in navigation stack", viewController);
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexOfViewController + 1, _viewControllers.count - (indexOfViewController + 1))];
    [_viewControllers enumerateObjectsAtIndexes:indexesToRemove options:0 usingBlock:^(RKViewController *viewController, NSUInteger index, BOOL *stop) {
        viewController.navigationController = nil;
        viewController.navigationItem.leftView = nil;
    }];
    [_viewControllers removeObjectsAtIndexes:indexesToRemove];
    
    [self.visibleViewController viewWillDisappear:animated];
    [viewController viewWillAppear:animated];
    if(animated) {
        [self replaceVisibleViewWithViewPushingFromLeft:viewController.view completionHandler:^{
            [self.visibleViewController viewDidDisappear:animated];
            [viewController viewDidAppear:animated];
        }];
    } else {
        [self replaceVisibleViewWithView:viewController.view];
        
        [self.visibleViewController viewDidDisappear:animated];
        [viewController viewDidAppear:animated];
    }
    
    [_navigationBar popToNavigationItem:viewController.navigationItem animated:animated];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated
{
    if([self.viewControllers count] == 1)
        return;
    
    RKViewController *topViewController = self.topViewController;
    
    NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _viewControllers.count - 1)];
    [_viewControllers enumerateObjectsAtIndexes:indexesToRemove options:0 usingBlock:^(RKViewController *viewController, NSUInteger index, BOOL *stop) {
        viewController.navigationController = nil;
        viewController.navigationItem.leftView = nil;
    }];
    [_viewControllers removeObjectsAtIndexes:indexesToRemove];
    
    [self.visibleViewController viewWillDisappear:animated];
    [topViewController viewWillAppear:animated];
    if(animated) {
        [self replaceVisibleViewWithViewPushingFromLeft:topViewController.view completionHandler:^{
            [self.visibleViewController viewDidDisappear:animated];
            [topViewController viewDidAppear:animated];
        }];
    } else {
        [self replaceVisibleViewWithView:topViewController.view];
        
        [self.visibleViewController viewDidDisappear:animated];
        [topViewController viewDidAppear:animated];
    }
    
    [_navigationBar popToRootNavigationItemAnimated:animated];
}

#pragma mark - Changing Views

- (void)replaceVisibleViewWithView:(NSView *)view
{
    if(_visibleView) {
        [_visibleView removeFromSuperviewWithoutNeedingDisplay];
        _visibleView = nil;
    }
    
    _visibleView = view;
    
    if(_visibleView) {
        [_visibleView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_visibleView setFrame:self.contentView.bounds];
        [self.contentView addSubview:_visibleView];
    }
}

- (void)replaceVisibleViewWithViewPushingFromLeft:(NSView *)newView completionHandler:(dispatch_block_t)completionHandler
{
    if(!_visibleView) {
        [self replaceVisibleViewWithView:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.contentView.bounds;
    initialNewViewFrame.origin.x = -NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self.contentView addSubview:newView];
    
    NSView *oldView = _visibleView;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = NSMaxX(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleView = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
        
        if(completionHandler)
            completionHandler();
    }];
}

- (void)replaceVisibleViewWithViewPushingFromRight:(NSView *)newView completionHandler:(dispatch_block_t)completionHandler
{
    if(!_visibleView) {
        [self replaceVisibleViewWithView:newView];
        return;
    }
    
    NSRect initialNewViewFrame = self.contentView.bounds;
    initialNewViewFrame.origin.x = NSWidth(initialNewViewFrame);
    [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [newView setFrame:initialNewViewFrame];
    [self.contentView addSubview:newView];
    
    NSView *oldView = _visibleView;
    NSRect oldViewTargetFrame = oldView.frame;
    oldViewTargetFrame.origin.x = -NSWidth(oldViewTargetFrame);
    
    NSRect newViewTargetFrame = initialNewViewFrame;
    newViewTargetFrame.origin.x = 0;
    
    _visibleView = newView;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        
        [[oldView animator] setFrame:oldViewTargetFrame];
        [[newView animator] setFrame:newViewTargetFrame];
    } completionHandler:^{
        [oldView removeFromSuperviewWithoutNeedingDisplay];
        
        if(completionHandler)
            completionHandler();
    }];
}

@end
