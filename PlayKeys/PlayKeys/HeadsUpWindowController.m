//
//  HeadsUpWindowController.m
//  PlayKeys
//
//  Created by Kevin MacWhinnie on 5/27/13.
//
//

#import "HeadsUpWindowController.h"
#import "Pinna.h"
#import "BackgroundArtworkDisplayView.h"
#import "RKBorderlessWindow.h"
#import "RKKeyDispatcher.h"

@interface HeadsUpWindowController () <NSWindowDelegate>

@property (nonatomic) id <PinnaScriptingController> scriptingController;

@property (nonatomic) NSTimer *dismissalTimer;

@property (nonatomic, readonly) RKBorderlessWindow *window;

@end

@implementation HeadsUpWindowController

#pragma mark - Lifecycle

- (id)init
{
    return [super initWithWindowNibName:@"HeadsUpWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self.window center];
    self.window.level = NSStatusWindowLevel;
    
    __block __typeof(self) me = self;
    [self.window.keyListener setHandlerForKeyCode:/*escape*/53 block:^(NSUInteger modifierFlags) {
		[me close];
        
		return YES;
	}];
    
    self.scriptingController = [Pinna sharedPinna].scriptingController;
    
    [self update];
}

- (void)close
{
    NSDictionary *windowFadeOut = @{ NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect,
                                     NSViewAnimationTargetKey: [self window] };
    NSViewAnimation *fadeOut = [[NSViewAnimation alloc] initWithViewAnimations:@[ windowFadeOut ]];
    [fadeOut setAnimationBlockingMode:NSAnimationBlocking];
    [fadeOut setDuration:0.3];
    [fadeOut startAnimation];
    
    [super close];
    self.window.alphaValue = 1.0;
    
    if(_dismissalHandler)
        _dismissalHandler();
}

#pragma mark - Updating

- (void)update
{
    if(self.dismissalTimer)
        [self.dismissalTimer invalidate];
    
    self.dismissalTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                           target:self
                                                         selector:@selector(close)
                                                         userInfo:nil
                                                          repeats:NO];
    
    if(self.scriptingController.shuffleEnabled)
        self.playbackModeIndicatorImageView.image = [NSImage imageNamed:@"ShuffleMode"];
    else
        self.playbackModeIndicatorImageView.image = [NSImage imageNamed:@"PlayMode"];
    
    self.songArtworkImageView.image = [[NSImage alloc] initWithData:self.scriptingController.playingSongArtwork];
    
    id <PinnaSong> playingSong = self.scriptingController.playingSong;
    self.songNameLabel.stringValue = playingSong.name ?: @"";
    self.songDetailLabel.stringValue = [NSString stringWithFormat:@"%@ by %@", playingSong.album ?: @"Unknown Album", playingSong.artist ?: @"Unknown Artist"];
}

#pragma mark - Properties

@dynamic window;

@end
