//
//  RKBarButtonCell.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/7/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKBarButton.h"

@implementation RKBarButton

- (id)initWithType:(RKBarButtonType)type title:(NSString *)title target:(id)target action:(SEL)action
{
    if((self = [super initWithFrame:NSZeroRect])) {
        RKBarButtonCell *cell = [[RKBarButtonCell alloc] initWithType:type title:title];
        [self setCell:cell];
        [self setTarget:target];
        [self setAction:action];
        
        [self sizeToFit];
    }
    
    return self;
}

#pragma mark - Properties

- (void)setButtonType:(RKBarButtonType)buttonType
{
    [(RKBarButtonCell *)[self cell] setButtonType:buttonType];
    
    [self sizeToFit];
}

- (RKBarButtonType)buttonType
{
    return [(RKBarButtonCell *)[self cell] buttonType];
}

- (void)setTitle:(NSString *)aString
{
    [super setTitle:aString];
    
    [self sizeToFit];
}

- (void)setImage:(NSImage *)image
{
    [super setImage:image];
    
    [self sizeToFit];
}

@end
