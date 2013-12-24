//
//  RKNavigationItem.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKNavigationItem.h"

#define BUTTON_MARGIN   10.0

@implementation RKNavigationItem

- (id)initWithFrame:(NSRect)frameRect
{
    if((self = [super initWithFrame:frameRect])) {
        NSTextField *labelField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        
        Class EtchedTextFieldCell = NSClassFromString(@"EtchedTextFieldCell");
        if(EtchedTextFieldCell) {
            [labelField setCell:[[EtchedTextFieldCell alloc] initTextCell:@""]];
        }
        
        [labelField setBordered:NO];
        [labelField setBezeled:NO];
        [labelField setEditable:NO];
        [labelField setEditable:NO];
        [labelField setBackgroundColor:[NSColor clearColor]];
        [labelField setTextColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.8]];
        [labelField setFont:[NSFont boldSystemFontOfSize:15.0]];
        [labelField setAlignment:NSCenterTextAlignment];
        [labelField setStringValue:@"Unnamed Navigation Item"];
        [labelField sizeToFit];
        self.titleView = labelField;
    }
    
    return self;
}

- (id)init
{
    return [self initWithFrame:NSMakeRect(0.0, 0.0, 250.0, 40.0)];
}

#pragma mark - Properties

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    
    if([self.titleView respondsToSelector:@selector(setStringValue:)])
        [(NSTextField *)self.titleView setStringValue:title ?: @""];
}

#pragma mark - Views

- (void)setLeftView:(NSView *)leftButton
{
    if(_leftView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewFrameDidChangeNotification
                                                      object:_leftView];
        
        [_leftView removeFromSuperview];
        _leftView = nil;
    }
    
    _leftView = leftButton;
    
    if(leftButton) {
        [leftButton setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(layoutViews)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:leftButton];
        
        [self addSubview:leftButton];
    }
    
    [self layoutViews];
}

- (void)setTitleView:(NSView *)titleView
{
    if(_titleView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewFrameDidChangeNotification
                                                      object:_titleView];
        
        [_titleView removeFromSuperview];
        _titleView = nil;
    }
    
    _titleView = titleView;
    
    if(titleView) {
        [titleView setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(layoutViews)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:titleView];
        
        [self addSubview:titleView];
        titleView.autoresizingMask = NSViewWidthSizable;
    }
    
    [self layoutViews];
}

- (void)setRightView:(NSView *)rightButton
{
    if(_rightView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSViewFrameDidChangeNotification
                                                      object:_rightView];
        
        [_rightView removeFromSuperview];
        _rightView = nil;
    }
    
    _rightView = rightButton;
    
    if(rightButton) {
        [rightButton setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(layoutViews)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:rightButton];
        
        [self addSubview:rightButton];
        rightButton.autoresizingMask = NSViewMaxXMargin;
    }
    
    [self layoutViews];
}

#pragma mark - Layout

- (void)layoutViews
{
    NSRect bounds = [self bounds];
    bounds.size.height--;
    
    NSRect leftButtonFrame = self.leftView? self.leftView.frame : NSZeroRect;
    NSRect titleViewFrame = self.titleView? self.titleView.frame : NSZeroRect;
    NSRect rightButtonFrame = self.rightView? self.rightView.frame : NSZeroRect;
    
    leftButtonFrame.origin.x = NSMinX(bounds) + BUTTON_MARGIN;
    leftButtonFrame.origin.y = round(NSMidY(bounds) - NSHeight(leftButtonFrame) / 2.0);
    
    CGFloat leftButtonMargin = self.leftView? BUTTON_MARGIN : 0.0;
    CGFloat rightButtonMargin = self.rightView? BUTTON_MARGIN : 0.0;
    
    titleViewFrame.size.width = NSWidth(bounds) - (NSWidth(leftButtonFrame) + NSWidth(rightButtonFrame) + leftButtonMargin + rightButtonMargin + (BUTTON_MARGIN * 2.0));
    if(NSWidth(titleViewFrame) / 2.0 <= leftButtonMargin)
        titleViewFrame.origin.x = NSMaxX(leftButtonFrame) + leftButtonMargin;
    else
        titleViewFrame.origin.x = round(NSMidX(bounds) - NSWidth(titleViewFrame) / 2.0);
    titleViewFrame.origin.y = round(NSMidY(bounds) - NSHeight(titleViewFrame) / 2.0);
    
    rightButtonFrame.origin.x = NSMaxX(titleViewFrame) + BUTTON_MARGIN;
    rightButtonFrame.origin.y = round(NSMidY(bounds) - NSHeight(rightButtonFrame) / 2.0);
    
    [self.leftView setFrame:leftButtonFrame];
    [self.titleView setFrame:titleViewFrame];
    [self.rightView setFrame:rightButtonFrame];
}

- (void)viewDidMoveToSuperview
{
    [self layoutViews];
}

@end
