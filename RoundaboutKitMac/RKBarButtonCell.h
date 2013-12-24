//
//  RKBarButtonCell.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/7/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///The different types of bar buttons.
typedef enum : NSUInteger {
    
    ///The default rounded type.
    kRKBarButtonTypeDefault = 0,
    
    ///The back button with an arrow on its left side.
    kRKBarButtonTypeBackButton = 1,
    
} RKBarButtonType;

///The RKBarButtonCell implements the display/sizing logic for the RKBarButton class.
@interface RKBarButtonCell : NSButtonCell

///Initialize the receiver with a given bar button type.
- (RKBarButtonCell *)initWithType:(RKBarButtonType)type title:(NSString *)title;

#pragma mark - Properties

///The type of the button.
@property (nonatomic) RKBarButtonType buttonType;

@end
