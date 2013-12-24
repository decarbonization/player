//
//  RKView.h
//  Pinna
//
//  Created by Kevin MacWhinnie on 5/8/13.
//
//

#import <Cocoa/Cocoa.h>

///The RKView class is a layer-backed subclas of NSView
///that adds several convenient methods from UIView.
@interface RKView : NSView

///The background color of the view.
@property (nonatomic) NSColor *backgroundColor;

@end
