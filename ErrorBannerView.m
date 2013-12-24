//
//  ErrorPresentationView.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 10/12/12.
//
//

#import "ErrorBannerView.h"

#import "RKAnimator.h"
#import "RKChromeView.h"

#import "NS(Attributed)String+Geometrics.h"

@interface ErrorPresentationViewController : NSViewController <RKChromeViewDelegate>
{
}

#pragma mark Outlets

@property (nonatomic, assign) IBOutlet NSImageView *iconView;

@property (nonatomic, assign) IBOutlet NSTextField *titleLabel;

@property (nonatomic, assign) IBOutlet NSButton *button;

#pragma mark - Properties

@property (nonatomic, assign) ErrorBannerView *parentView;

@end

@implementation ErrorPresentationViewController

- (id)init
{
	if((self = [super initWithNibName:@"ErrorPresentationView" bundle:nil]))
	{
		
	}
	
	return self;
}

- (void)sizeToFit
{
	NSRect titleLabelFrame = [self.titleLabel frame];
	
	CGFloat properHeight = [self.titleLabel.attributedStringValue heightForWidth:NSWidth(self.titleLabel.frame)];
	CGFloat heightDelta = NSHeight(titleLabelFrame) - properHeight;
	
	titleLabelFrame.origin.y -= heightDelta;
	titleLabelFrame.size.height += heightDelta;
	
	[self.titleLabel setFrame:titleLabelFrame];
	
	NSRect frame = [self.view frame];
	frame.size.height += heightDelta;
	[self.view setFrame:frame];
}

#pragma mark - RKChromeViewDelegate

- (void)windowChromeViewWasClicked:(RKChromeView *)windowChromeView
{
	[self.parentView close];
}

@end

#pragma mark -

@implementation ErrorBannerView

- (id)init
{
	if((self = [super init]))
	{
		mErrorPresentationViewController = [ErrorPresentationViewController new];
		mErrorPresentationViewController.parentView = self;
		self.title = @"Unknown Error";
		self.buttonTitle = @"Dismiss";
		
		__block ErrorBannerView *me = self;
		self.buttonAction = ^{ [me close]; };
	}
	
	return self;
}

#pragma mark - Properties

@synthesize title = mTitle;
@synthesize buttonTitle = mButtonTitle;
@synthesize buttonAction = mButtonAction;

#pragma mark -

- (BOOL)isVisible
{
	return ([self superview] != nil);
}

#pragma mark - Presentation

- (void)showInView:(NSView *)parentView
{
	NSParameterAssert(parentView);
	NSAssert(!self.isVisible, @"Cannot show an error presentation view more than once.");
	
	NSRect frame = { .origin = NSZeroPoint, .size = [parentView frame].size };
	[self setFrame:frame];
	[parentView addSubview:self];
	
	NSView *errorPresentationView = mErrorPresentationViewController.view;
	mErrorPresentationViewController.titleLabel.stringValue = self.title ?: @"";
	mErrorPresentationViewController.button.title = self.buttonTitle ?: @"";
	mErrorPresentationViewController.button.target = self;
	mErrorPresentationViewController.button.action = @selector(invokeAction:);
	
	//[mErrorPresentationViewController sizeToFit];
	
	NSRect initialRect = NSMakeRect(0.0, NSMaxY([self frame]),
									NSWidth([self frame]), NSHeight([errorPresentationView frame]));
	[errorPresentationView setFrame:initialRect];
	[self addSubview:errorPresentationView];
	
	NSRect finalRect = initialRect;
	finalRect.origin.y = NSMaxY([self frame]) - NSHeight(initialRect);
	
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction setFrame:finalRect forTarget:errorPresentationView];
    } completionHandler:^(BOOL didFinish) {
        mCloseTimer = [NSTimer scheduledTimerWithTimeInterval:3.5
													   target:self
													 selector:@selector(close)
													 userInfo:nil
													  repeats:NO];
    }];
}

- (void)close
{
	if(!self.isVisible)
		return;
	
	[mCloseTimer invalidate];
	mCloseTimer = nil;
	
    [[RKAnimator animator] transaction:^(RKAnimatorTransaction *transaction) {
        [transaction fadeOutTarget:self];
    } completionHandler:^(BOOL didFinish) {
		[mErrorPresentationViewController.view removeFromSuperviewWithoutNeedingDisplay];
		[self removeFromSuperview];
	}];
}

#pragma mark - Glue

- (IBAction)invokeAction:(id)sender
{
	if(self.buttonAction)
		self.buttonAction();
}

@end
