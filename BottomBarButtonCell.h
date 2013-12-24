//
//  BottomBarButtonCell.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 8/4/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BottomBarButtonCell : NSButtonCell
{
	BOOL mIsLeftMostButton;
	BOOL mIsRightMostButton;
}

#pragma mark - Properties

@property (nonatomic) BOOL isLeftMostButton;
@property (nonatomic) BOOL isRightMostButton;

@end
