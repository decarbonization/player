//
//  RKBarButtonCell.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/7/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RKBarButtonCell.h"

///The RKBarButton class is a subclass of NSButton used by RKNavigationItem
///instances to present navigation options to the user.
///
///Changing the title of image of a bar button will cause it to update its metrics.
@interface RKBarButton : NSButton

///Initialize the receiver with a given button type and basic parameters.
- (id)initWithType:(RKBarButtonType)type
             title:(NSString *)title
            target:(id)target
            action:(SEL)action;

#pragma mark - Properties

///The type of the button.
@property (nonatomic) RKBarButtonType buttonType;

@end
