//
//  BrowserModeMatrix.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/18/13.
//
//

#import <Cocoa/Cocoa.h>

///The BrowserModeMatrix subclass registers itself as a drop target for Songs,
///and will switch to a specified mode when a user holds a song over the matrix
///for one-half second.
@interface BrowserModeMatrix : NSMatrix

///The mode to switch to when a user holds a song over the matrix.
@property (nonatomic) NSUInteger dropTargetMode;

///Whether or not the matrix should switch back after the drag operation is completed.
@property (nonatomic) BOOL shouldRevertToPreviousMode;

@end
