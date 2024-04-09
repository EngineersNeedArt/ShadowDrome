//
//  OverlayView.m
//  Shadowdrome
//

#import "OverlayView.h"


@interface OverlayView ()
	
@end

@implementation OverlayView

NSPoint _crosshair;
NSSize _contextSize;

- (id) initWithFrame: (NSRect) frameRect {
	[self clearCrossHair];
	
	// Super.
	return [super initWithFrame: frameRect];
}

- (void) drawRect: (NSRect) dirtyRect {
	// Super.
	[super drawRect: dirtyRect];
	
	if ((_crosshair.x >= 0.0) && (_crosshair.y >= 0.0)) {
		CGFloat height = self.frame.size.height;
		CGFloat width = self.frame.size.width;
		CGFloat x = (_crosshair.x * width / _contextSize.width) + 1;
		CGFloat y = height - ((_crosshair.y * height / _contextSize.height) + 1);
		[[NSColor redColor] setStroke];
		NSBezierPath *linePath = [NSBezierPath bezierPath];
		[linePath moveToPoint: NSMakePoint (x - 10, y)];
		[linePath lineToPoint: NSMakePoint (x + 10, y)];
		[linePath moveToPoint: NSMakePoint (x, y - 10)];
		[linePath lineToPoint: NSMakePoint (x, y + 10)];
		[linePath setLineWidth: 2.0];
		[linePath stroke];
	}
}

- (void) setContextSize: (NSSize) size {
	_contextSize = size;
	[self setNeedsDisplay: YES];
}

- (void) setCrosshair: (NSPoint) point {
	_crosshair.x = point.x;
	_crosshair.y = point.y;
	[self setNeedsDisplay: YES];
}

- (void) clearCrossHair {
	_crosshair.x = -1.0;
	_crosshair.y = -1.0;
}

@end
