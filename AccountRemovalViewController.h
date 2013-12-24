//
//  AccountRemovalViewController.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "RKViewController.h"

@class RKSideSheetView, Account;

@interface AccountRemovalViewController : RKViewController

- (id)initWithAccount:(Account *)account;

#pragma mark - Properties

@property (nonatomic) Account *account;

@property (nonatomic, weak) RKSideSheetView *containingSheet;

#pragma mark - Actions

- (IBAction)cancel:(id)sender;

- (IBAction)remove:(id)sender;

@end
