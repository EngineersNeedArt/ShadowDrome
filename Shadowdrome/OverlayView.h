//
//  OverlayView.h
//  Shadowdrome
//
//  Created by John Calhoun on 4/9/24.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface OverlayView : NSView
	- (void) setContextSize: (NSSize) size;
	- (void) setCrosshair: (NSPoint) point;
	- (void) clearCrossHair;
@end

NS_ASSUME_NONNULL_END
