//
//  BrowserModeMatrix.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 2/18/13.
//
//

#import "BrowserModeMatrix.h"

#import "Song.h"

@implementation BrowserModeMatrix {
    NSTimer *_delay;
    NSUInteger _selectedModeBeforeDrag;
}

- (void)awakeFromNib
{
    self.dropTargetMode = 0;
    self.shouldRevertToPreviousMode = YES;
    
    [self registerForDraggedTypes:@[kSongUTI]];
}

#pragma mark - Drag Popover

- (void)showPopoverAfterDelay:(NSTimer *)timer
{
    if([self selectedColumn] != self.dropTargetMode)
    {
        _selectedModeBeforeDrag = [self selectedColumn];
        
        [self selectCellAtRow:0 column:self.dropTargetMode];
        [self sendAction];
    }
    
    _delay = nil;
}

#pragma mark - <NSDraggingDestination>

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    [_delay invalidate];
    _delay = [NSTimer scheduledTimerWithTimeInterval:0.5
                                              target:self
                                            selector:@selector(showPopoverAfterDelay:)
                                            userInfo:nil
                                             repeats:NO];
    
    return NSDragOperationCopy;
}

- (void)draggingEnded:(id < NSDraggingInfo >)sender
{
    if(self.shouldRevertToPreviousMode)
    {
        [self selectCellAtRow:0 column:_selectedModeBeforeDrag];
        [self sendAction];
    }
    
    [_delay invalidate];
    _delay = nil;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
    [_delay invalidate];
    _delay = nil;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
    return NO;
}

@end
