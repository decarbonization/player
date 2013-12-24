//
//  RKNavigationOverlayView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/7/13.
//
//

#import "RKSideSheetView.h"
#import "RoundaboutKitMac.h"

@interface RKSideSheetView ()

@property (nonatomic, readwrite) RKNavigationController *navigationController;
@property (nonatomic, weak) NSView *navigationView;

@end

@implementation RKSideSheetView

- (id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame])) {
        self.wantsLayer = YES;
        
        self.navigationController = [[RKNavigationController alloc] initWithRootViewController:nil];
        self.navigationView = self.navigationController.view;
        _navigationView.hidden = YES;
        _navigationView.wantsLayer = YES;
        CGColorRef windowColor = CGColorCreateGenericRGB(0.93, 0.93, 0.93, 1.00);
        _navigationView.layer.backgroundColor = windowColor;
        CGColorRelease(windowColor);
        _navigationView.layer.shadowColor = CGColorGetConstantColor(kCGColorBlack);
        _navigationView.layer.shadowRadius = 5.0;
        _navigationView.layer.shadowOpacity = 0.4;
        
        [self addSubview:self.navigationController.view];
        
        RKView *defaultBackgroundView = [RKView new];
        defaultBackgroundView.backgroundColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.6];
        self.backgroundView = defaultBackgroundView;
        
        self.contentWidth = 320.0;
    }
    
    return self;
}

#pragma mark - Properties

- (void)setBackgroundView:(RKView *)backgroundView
{
    CGFloat targetAlphaValue = 0.0;
    if(_backgroundView) {
        targetAlphaValue = _backgroundView.alphaValue;
        [_backgroundView removeFromSuperview];
    }
    
    _backgroundView = backgroundView;
    
    if(backgroundView) {
        NSRect frame;
        frame.origin = NSZeroPoint;
        frame.size = self.frame.size;
        backgroundView.frame = frame;
        backgroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        backgroundView.alphaValue = targetAlphaValue;
        [self addSubview:backgroundView positioned:NSWindowBelow relativeTo:_navigationView];
    }
}

#pragma mark - Event Handling

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

#pragma mark - Showing/Hiding The Overlay

- (void)showInView:(NSView *)view animated:(BOOL)animated completionHandler:(dispatch_block_t)completionHandler
{
    NSParameterAssert(view);
    
    NSRect frame = NSZeroRect;
    frame.size = view.frame.size;
    self.frame = frame;
    [view addSubview:self];
    
    NSRect navigationViewFrame = _navigationView.frame;
    navigationViewFrame.size.width = self.contentWidth;
    navigationViewFrame.size.height = NSHeight(frame);
    navigationViewFrame.origin.y = 0.0;
    navigationViewFrame.origin.x = NSMaxX(frame);
    _navigationView.frame = navigationViewFrame;
    _navigationView.hidden = NO;
    
    navigationViewFrame.origin.x = NSMaxX(frame) - NSWidth(navigationViewFrame);
    
    if(animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.25;
            
            [[_backgroundView animator] setAlphaValue:1.0];
            [[_navigationView animator] setFrame:navigationViewFrame];
        } completionHandler:completionHandler];
    } else {
        [_backgroundView setAlphaValue:1.0];
        [_navigationView setFrame:navigationViewFrame];
        
        if(completionHandler)
            completionHandler();
    }
}

- (void)dismiss:(BOOL)animated completionHandler:(dispatch_block_t)completionHandler
{
    NSRect frame = self.frame;
    
    NSRect navigationViewFrame = _navigationView.frame;
    navigationViewFrame.origin.x = NSMaxX(frame);
    
    if(animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.25;
            
            [[_backgroundView animator] setAlphaValue:0.0];
            [[_navigationView animator] setFrame:navigationViewFrame];
        } completionHandler:^{
            [self removeFromSuperview];
            
            if(_dismissalHandler)
                _dismissalHandler(self);
            
            if(completionHandler)
                completionHandler();
        }];
    } else {
        [_backgroundView setAlphaValue:0.0];
        [_navigationView setFrame:navigationViewFrame];
        
        [self removeFromSuperview];
        
        if(_dismissalHandler)
            _dismissalHandler(self);
        
        if(completionHandler)
            completionHandler();
    }
}

@end
