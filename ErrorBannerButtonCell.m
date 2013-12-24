//
//  ErrorBannerButtonCell.m
//  Pinna
//
//  Created by Kevin MacWhinnie on 10/14/12.
//
//

#import "ErrorBannerButtonCell.h"

@implementation ErrorBannerButtonCell

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSMutableAttributedString *ourTitle = [title mutableCopy];
	[ourTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, ourTitle.length)];
	[ourTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, ourTitle.length)];
	return [super drawTitle:ourTitle withFrame:frame inView:controlView];
}

@end
