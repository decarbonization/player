//
//  RKViewController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKViewController.h"
#import "RKViewController_Private.h"
#import "RKNavigationController.h"
#import "RKNavigationItem.h"

@implementation RKViewController {
    RKNavigationItem *_navigationItem;
    NSMutableArray *_childViewControllers;
}

- (id)initWithView:(NSView *)view
{
    NSParameterAssert(view);
    
    if((self = [super init])) {
        [self viewWillLoad];
        
        self.view = view;
        self.isViewLoaded = YES;
        
        [self viewDidLoad];
    }
    
    return self;
}

- (id)init
{
    return [self initWithNibName:self.nibName bundle:self.nibBundle];
}

#pragma mark -

- (NSBundle *)nibBundle
{
    return [NSBundle bundleForClass:[self class]];
}

- (NSString *)nibName
{
    NSBundle *nibBundle = self.nibBundle;
    
    NSString *nibName = nil;
    Class class = [self class];
    while (class && [nibBundle pathForResource:NSStringFromClass(class) ofType:@"nib"] == nil) {
        class = [class superclass];
    }
    
    if(class)
        nibName = NSStringFromClass(class);
    
    return nibName;
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewDidDisappear:(BOOL)animated
{
}

#pragma mark - Loading

- (void)viewWillLoad
{
}

- (void)viewDidLoad
{
}

- (void)loadView
{
    if(!self.isViewLoaded) {
        [self viewWillLoad];
        
        [super loadView];
        self.isViewLoaded = YES;
        
        [self viewDidLoad];
    }
}

#pragma mark - Navigation Stack Support

- (RKNavigationItem *)navigationItem
{
    if(!_navigationItem) {
        _navigationItem = [RKNavigationItem new];
        _navigationItem.title = NSStringFromClass([self class]);
    }
    
    return _navigationItem;
}

#pragma mark - Containing View Controllers

- (void)willMoveToParentViewController:(RKViewController *)parent
{
}

- (void)didMoveToParentViewController:(RKViewController *)parent
{
}

#pragma mark -

- (NSMutableArray *)mutableChildViewControllers
{
    if(!_childViewControllers)
        _childViewControllers = [NSMutableArray array];
    
    return _childViewControllers;
}

- (NSArray *)childViewControllers
{
    return [self mutableChildViewControllers];
}

- (void)addChildViewController:(RKViewController *)childController
{
    NSParameterAssert(childController);
    
    [childController willMoveToParentViewController:self];
    [[self mutableChildViewControllers] addObject:childController];
    [childController didMoveToParentViewController:self];
}

- (void)removeFromParentViewController
{
    [self willMoveToParentViewController:nil];
    [self.parentViewController->_childViewControllers removeObject:self];
    [self didMoveToParentViewController:nil];
}

#pragma mark - Actions

- (IBAction)popFromNavigationController:(id)sender
{
    if(self.navigationController.visibleViewController == self)
        [self.navigationController popViewControllerAnimated:YES];
}

@end
