//
//  UIViewController_Private.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 12/6/12.
//  Copyright (c) 2013 Roundabout Software, LLC. All rights reserved.
//

#import "RKViewController.h"

@interface RKViewController ()

@property (nonatomic, readwrite) BOOL isViewLoaded;
@property (nonatomic, readwrite, unsafe_unretained) RKNavigationController *navigationController;
@property (nonatomic, readwrite) RKViewController *parentViewController;

@end
