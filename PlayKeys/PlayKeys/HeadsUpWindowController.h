//
//  HeadsUpWindowController.h
//  PlayKeys
//
//  Created by Kevin MacWhinnie on 5/27/13.
//
//

#import <Cocoa/Cocoa.h>

@class BackgroundArtworkDisplayView;

///The HeadsUpWindowController class encapsulates the heads up controller that
///appears when the user press and holds the play-pause button on their keyboard.
@interface HeadsUpWindowController : NSWindowController

#pragma mark - Outlets

///The image view that displays the symbol for the current playback mode.
@property (nonatomic, assign) IBOutlet NSImageView *playbackModeIndicatorImageView;

///The song artwork image view.
@property (nonatomic, assign) IBOutlet BackgroundArtworkDisplayView *songArtworkImageView;

///The song name label.
@property (nonatomic, assign) IBOutlet NSTextField *songNameLabel;

///The song detail label.
@property (nonatomic, assign) IBOutlet NSTextField *songDetailLabel;

#pragma mark - Properties

///A block to invoke when the controller window closes.
@property (nonatomic, copy) dispatch_block_t dismissalHandler;

#pragma mark - Updating

///Update the contents of the heads up window.
- (void)update;

@end
