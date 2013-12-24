//
//  AccountRemovalViewController.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import "AccountRemovalViewController.h"
#import "RoundaboutKitMac.h"
#import "RKSideSheetView.h"

#import "ServiceDescriptor.h"
#import "AccountManager.h"

@interface AccountRemovalViewController ()

@end

@implementation AccountRemovalViewController

- (id)initWithAccount:(Account *)account
{
    NSParameterAssert(account);
    
    if((self = [super init])) {
        self.account = account;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.account.descriptor.name;
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    [self.containingSheet dismiss:YES completionHandler:nil];
}

- (IBAction)remove:(id)sender
{
    [[[AccountManager sharedAccountManager] deleteAccount:self.account] then:^(id <Service> service) {
        [self.containingSheet dismiss:YES completionHandler:nil];
    } otherwise:^(NSError *error) {
        [NSApp presentError:error];
        
        [self.containingSheet dismiss:YES completionHandler:nil];
    }];
}

@end
