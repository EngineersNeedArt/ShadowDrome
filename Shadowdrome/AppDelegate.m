//
//  AppDelegate.m
//  Shadowdrome
//
//  Created by John Calhoun on 3/7/24.
//

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "AppDelegate.h"
#include "OverlayView.h"
#include "BitmapContext.h"
#include "Lamp.h"
#include "Obstacle.h"
#include "ShadowContext.h"
#include "ShadowContextJSONLayer.h"


#define kNum_Queues	8

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSImageView *shadowImageView;
@property (strong) IBOutlet NSTableView *contextTableView;
@property (strong) IBOutlet NSTabView *detailTabView;

@property (strong) IBOutlet NSImageView *histogramImageView;

@property (strong) IBOutlet NSTextField *lampXTextField;
@property (strong) IBOutlet NSTextField *lampYTextField;
@property (strong) IBOutlet NSTextField *lampRadiusTextField;
@property (strong) IBOutlet NSTextField *lampIntensityTextField;

@property (strong) IBOutlet NSTextField *obstaclePolygonXTextField;
@property (strong) IBOutlet NSTextField *obstaclePolygonYTextField;
@property (strong) IBOutlet NSTextField *obstaclePolygonVerticesTextField;

@property (strong) IBOutlet NSTextField *obstacleCylinderXTextField;
@property (strong) IBOutlet NSTextField *obstacleCylinderYTextField;
@property (strong) IBOutlet NSTextField *obstacleCylinderRadiusTextField;
@property (strong) IBOutlet NSTextField *obstacleCylinderOpacityTextField;

@property (strong) IBOutlet NSTextField *obstacleRectangleXTextField;
@property (strong) IBOutlet NSTextField *obstacleRectangleYTextField;
@property (strong) IBOutlet NSTextField *obstacleRectangleWidthTextField;
@property (strong) IBOutlet NSTextField *obstacleRectangleHeightTextField;
@property (strong) IBOutlet NSTextField *obstacleRectangleRotationTextField;
@property (strong) IBOutlet NSTextField *obstacleRectangleOpacityTextField;

@property (strong) IBOutlet NSTextField *value1TextField;	// Temporary, experimental value.
@property (strong) IBOutlet NSTextField *value2TextField;	// Temporary, experimental value.

@property (strong) IBOutlet NSWindow *contextWindow;
@property (strong) IBOutlet NSTextField *contextNameTextField;
@property (strong) IBOutlet NSTextField *contextWidthTextField;
@property (strong) IBOutlet NSTextField *contextHeightTextField;

@property (strong) OverlayView *overlayView;

@property (strong) NSString *contextJSON;
@end

@implementation AppDelegate

BMContext *bitmap;
SDContext *shadowContext;
BOOL newObjectAdded = NO;
NSInteger wasSelectedRow = -1;
BOOL renderComplete = YES;
NSInteger nextRenderX = 0;
NSInteger nextRenderY = 0;
NSInteger renderIdentifier = -1;
double renderScale = 1.0;
NSMutableArray<NSString *> *objectQueue = NULL;

- (NSTextField *) _findOwningTextFieldFromTextView: (NSTextView *)textView {
	NSView *view = textView;
	
	// Traverse the view hierarchy upwards until we find an NSTextField or reach the top
	while (view != nil) {
		// Check if the current view is an NSTextField
		if ([view isKindOfClass: [NSTextField class]]) {
			return (NSTextField *) view;
		}
		// Move up to the superview
		view = [view superview];
	}
	
	// If no owning NSTextField is found
	return nil;
}

- (BOOL) _takeDataFromTextField: (NSTextField *) textField {
	NSInteger tag = [textField tag];
	NSInteger index = wasSelectedRow;
	if (index >= sdContextNumberOfLamps (shadowContext)) {
		index -= sdContextNumberOfLamps (shadowContext);
		Obstacle *obstacle = sdContextObstacleAtIndex (shadowContext, (int) index);
		switch (tag) {
			case 0:
			if (obstacle->xCenter == round ([textField doubleValue])) {
				return NO;
			}
			obstacleSetXY (obstacle, round ([textField doubleValue]), obstacle->yCenter);
			break;
			
			case 1:
			if (obstacle->yCenter == round ([textField doubleValue])) {
				return NO;
			}
			obstacleSetXY (obstacle, obstacle->xCenter, round ([textField doubleValue]));
			break;
			
			case 2:
			if (obstacle->radius == round ([textField doubleValue])) {
				return NO;
			}
			obstacleSetRadius (obstacle, round ([textField doubleValue]));
			break;
			
			case 3:
			if (obstacle->rotationDegrees == [textField doubleValue]) {
				return NO;
			}
			obstacleSetRotationDegrees (obstacle, [textField doubleValue]);
			break;
			
			case 4:
			if (obstacle->width == round ([textField doubleValue])) {
				return NO;
			}
			obstacleSetWidth (obstacle, round ([textField doubleValue]));
			break;
			
			case 5:
			if (obstacle->height == round ([textField doubleValue])) {
				return NO;
			}
			obstacleSetHeight (obstacle, round ([textField doubleValue]));
			break;
			
			case 6:
			if (obstacle->opacity == [textField doubleValue]) {
				return NO;
			}
			obstacle->opacity = [textField doubleValue];
			break;
			
			default:
			break;
		}
	} else {
		Lamp *lamp = sdContextLampAtIndex (shadowContext, (int) index);
		switch (tag) {
			case 0:
			if (lamp->xLoc == round ([textField doubleValue])) {
				return NO;
			}
			lamp->xLoc = round ([textField doubleValue]);
			break;
			
			case 1:
			if (lamp->yLoc == round ([textField doubleValue])) {
				return NO;
			}
			lamp->yLoc = round ([textField doubleValue]);
			break;
			
			case 2:
			if (lamp->radius == round ([textField doubleValue])) {
				return NO;
			}
			lamp->radius = round ([textField doubleValue]);
			break;
			
			case 3:
			if (lamp->intensity == round ([textField doubleValue])) {
				return NO;
			}
			lamp->intensity = round ([textField doubleValue]);
			break;
			
			default:
			break;
		}
	}
	
	return YES;
}

- (void) _captureTextFieldEditor {
	NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSResponder *currentResponder = [keyWindow firstResponder];
	if ([currentResponder isKindOfClass: [NSTextView class]]) {
		NSTextField *textField = [self _findOwningTextFieldFromTextView: (NSTextView *) currentResponder];
		if ([textField currentEditor] != NULL) {
			BOOL changed = [self _takeDataFromTextField: textField];
			if (changed) {
				[self _kickOffRenderAndDisplay];
			}
		}
	}
}

- (void) _showDetailForObjectAtIndex: (NSInteger) index {
	if ((shadowContext == NULL) || (index < 0) || (index >= (sdContextNumberOfLamps (shadowContext) + sdContextNumberOfObstacles (shadowContext)))) {
		[_detailTabView selectTabViewItemAtIndex: 4];
		return;
	}
	
	if (index < sdContextNumberOfLamps (shadowContext)) {
		[_detailTabView selectTabViewItemAtIndex: 0];
		Lamp *lamp = sdContextLampAtIndex (shadowContext, (int) index);
		if (lamp) {
			[_lampXTextField setIntValue: lamp->xLoc];
			[_lampYTextField setIntValue: lamp->yLoc];
			[_lampRadiusTextField setIntValue: lamp->radius];
			[_lampIntensityTextField setIntValue: lamp->intensity];
		}
	} else {
		index = index - sdContextNumberOfLamps (shadowContext);
		Obstacle *obstacle = sdContextObstacleAtIndex (shadowContext, (int) index);
		if (obstacle) {
			switch (obstacle->kind) {
				case ObstacleKindPolygonalPrism:
				[_detailTabView selectTabViewItemAtIndex: 1];
				[_obstaclePolygonXTextField setIntValue: obstacle->xCenter];
				[_obstaclePolygonYTextField setIntValue: obstacle->yCenter];
					[_obstaclePolygonVerticesTextField setStringValue: [NSString stringWithFormat: @"%d vertices. Not currently editable.", obstacle->numVertices]];
				break;
				
				case ObstacleKindCylinder:
				[_detailTabView selectTabViewItemAtIndex: 2];
				[_obstacleCylinderXTextField setIntValue: obstacle->xCenter];
				[_obstacleCylinderYTextField setIntValue: obstacle->yCenter];
				[_obstacleCylinderRadiusTextField setIntValue: obstacle->radius];
				[_obstacleCylinderOpacityTextField setDoubleValue: obstacle->opacity];
				break;
				
				case ObstacleKindRectangularPrism:
				[_detailTabView selectTabViewItemAtIndex: 3];
				[_obstacleRectangleXTextField setIntValue: obstacle->xCenter];
				[_obstacleRectangleYTextField setIntValue: obstacle->yCenter];
				[_obstacleRectangleWidthTextField setIntValue: obstacle->width];
				[_obstacleRectangleHeightTextField setIntValue: obstacle->height];
				[_obstacleRectangleRotationTextField setDoubleValue: obstacle->rotationDegrees];
				[_obstacleRectangleOpacityTextField setDoubleValue: obstacle->opacity];
				break;
				
				default:
				break;
			}
		}
	}
}

- (void) _writeFullsizeBitmapDataToURL: (NSURL *) url {
	BMContext *fullBitmap;
	
	fullBitmap = bmContextCreate (shadowContext->width, shadowContext->height);
	bmContextFillBuffer (fullBitmap, 0, 0, 0, 255);
	
	[self _renderToBitmap: fullBitmap async: NO completion: ^(BOOL success) {
		NSData *bitmapData = NULL;
		CGDataProviderRef provider = CGDataProviderCreateWithData (NULL, bmContextBufferPtr(fullBitmap), bmContextBufferSize (fullBitmap), NULL);
		CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
		CGImageRef imageRef = CGImageCreate(bmContextWidth (fullBitmap), bmContextHeight (fullBitmap), 8, 32,
				4 * bmContextWidth (fullBitmap), colorSpaceRef,
				kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, provider, NULL, YES,
				kCGRenderingIntentDefault);
		
		NSImage *image = [[NSImage alloc] initWithCGImage: imageRef
				size: NSMakeSize (bmContextWidth (fullBitmap), bmContextHeight (fullBitmap))];
		
		// No compression
		NSData *data = [image TIFFRepresentation];
		if (data != nil) {
			NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData: data];
			if (bitmapRep != nil) {
				bitmapData = [bitmapRep representationUsingType: NSBitmapImageFileTypePNG properties: @{}];
			}
		}
		
		CGImageRelease (imageRef);
		CGColorSpaceRelease (colorSpaceRef);
		CGDataProviderRelease (provider);
		
		if (bitmapData) {
			[bitmapData writeToURL: url atomically: YES];
		}
	}];

	
//	CGDataProviderRef provider = CGDataProviderCreateWithData (NULL, bmContextBufferPtr(fullBitmap), bmContextBufferSize(fullBitmap), NULL);
//	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
//	CGImageRef imageRef = CGImageCreate(bmContextWidth (fullBitmap), bmContextHeight (fullBitmap), 8, 32,
//			4 * bmContextWidth (fullBitmap), colorSpaceRef,
//			kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, provider, NULL, YES,
//			kCGRenderingIntentDefault);
//	
//	NSImage *image = [[NSImage alloc] initWithCGImage: imageRef
//			size: NSMakeSize (bmContextWidth (fullBitmap), bmContextHeight (fullBitmap))];
//	
//	// No compression
//	NSData *data = [image TIFFRepresentation];
//	if (data != nil) {
//		NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData: data];
//		if (bitmapRep != nil) {
//			bitmapData = [bitmapRep representationUsingType: NSBitmapImageFileTypePNG properties: @{}];
//		}
//	}
//	
//	CGImageRelease (imageRef);
//	CGColorSpaceRelease (colorSpaceRef);
//	CGDataProviderRelease (provider);
//	
//	return bitmapData;
}

- (void) _resetRenderQueue {
	nextRenderX = 0;
	nextRenderY = 0;
	renderComplete = NO;
	renderIdentifier = renderIdentifier + 1;
}

// Must be called from main thread.
- (BOOL) _nextPixelLocationToRenderX: (NSInteger *) x Y: (NSInteger *) y {
	if (renderComplete) {
		return NO;
	} else {
		*x = nextRenderX;
		*y = nextRenderY;
		
		// Increment x.
		nextRenderX = nextRenderX + 1;
		if (nextRenderX > shadowContext->width) {
			// If we've reached the ned of a row, increment y, start x back at start of new row.
			nextRenderX = 0;
			nextRenderY = nextRenderY + 1;
			if (nextRenderY > shadowContext->height) {
				// If we have completed all rows, the render is complete.
				nextRenderY = 0;
				renderComplete = YES;
			}
		}
	}
	
	return YES;
}

// Must be called from main thread.
- (void) _displayRenderedBitmap {
	CGDataProviderRef provider = CGDataProviderCreateWithData (NULL, bmContextBufferPtr(bitmap), bmContextBufferSize(bitmap), NULL);
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGImageRef imageRef = CGImageCreate(bmContextWidth (bitmap), bmContextHeight (bitmap), 8, 32,
			4 * bmContextWidth (bitmap), colorSpaceRef,
			kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, provider, NULL, YES,
			kCGRenderingIntentDefault);
	
	NSImage *image = [[NSImage alloc] initWithCGImage: imageRef
			size: NSMakeSize (bmContextWidth (bitmap), bmContextHeight (bitmap))];
	self.shadowImageView.image = image;
	
	CGImageRelease (imageRef);
	CGColorSpaceRelease (colorSpaceRef);
	CGDataProviderRelease (provider);
}

- (void) _generateHistogram {
	size_t bufferSize = sizeof (unsigned int) * 256;
	unsigned int *buffer = malloc (bufferSize);
	memset (buffer, 0, bufferSize);
	(void) bmContextHistogram (bitmap, 3, buffer);
	
	NSRect frame = [_histogramImageView frame];
	NSImage *image = [[NSImage alloc] initWithSize: frame.size];
	[image lockFocus];
	int column = 0;
	int stride = 256 / frame.size.width;
	
	// Find largest column total for vertical scaling purposes.
	long largestColumnTotal = 0L;
	do {
		long columnTotal = 0L;
		for (int c = column; c < (column + stride); c++) {
			columnTotal += buffer[c];
		}
		if (columnTotal > largestColumnTotal) {
			largestColumnTotal = columnTotal;
		}
		column += stride;
	} while (column < 256);
	
	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	CGContextRef context = [graphicsContext CGContext];
	CGContextSetLineWidth (context, 1.0);
	column = 0;
	int columnIndex = 0;
	do {
		long columnTotal = 0;
		for (int c = column; c < (column + stride); c++) {
			columnTotal += buffer[c];
		}
		CGFloat barHeight = (CGFloat) columnTotal * frame.size.height / (CGFloat) largestColumnTotal;
		
		// Clear column white.
		CGContextSetRGBStrokeColor (context, 1.0, 1.0, 1.0, 1.0);
		CGContextMoveToPoint (context, columnIndex, 0);
		CGContextAddLineToPoint (context, columnIndex, frame.size.height);
		CGContextStrokePath (context);
		
		CGContextSetRGBStrokeColor (context, 0.0, 0.0, 0.0, 1.0);
		CGContextMoveToPoint (context, columnIndex, 0);
		CGContextAddLineToPoint (context, columnIndex, barHeight);
		CGContextStrokePath (context);
		
		column += stride;
		columnIndex += 1;
	} while (column < 256);
	
	[image unlockFocus];
	_histogramImageView.image = image;
	
	free (buffer);
}

- (void) _renderCore: (BMContext *) bitmap completion: (void (^)(BOOL success)) completionBlock {
	// Create a dispatch group to keep track of completion
	dispatch_group_t group = dispatch_group_create ();
	
	// Iterate through each pixel in the bitmap and dispatch tasks to the worker queues.
	NSInteger identifier = renderIdentifier;
	int width = bmContextWidth (bitmap);
	int height = bmContextHeight (bitmap);
	for (int y = 0; y < height; y++) {
		dispatch_group_async (group, dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			// Let's do one row's worth of pixel data in one dispatch.
			// Tryiong to go too fine grain seems to lead to slowdown from thread management overhead.
			for (int x = 0; x < width; x++) {
				if (identifier == renderIdentifier) {
					double scaledX = (double) x / renderScale;
					double scaledY = (double) y / renderScale;
					double luminance = sdContextGetLuminanceForPoint (shadowContext, scaledX, scaledY);
					luminance = luminance * 255.0;
					luminance = MIN (luminance, 255.0);
					luminance = MAX (luminance, 0.0);
					
					unsigned char red, green, blue, alpha;
					bmContextGetPixel (bitmap, x, y, &red, &green, &blue, &alpha);
					if (alpha > round (luminance)) {
						alpha = alpha - round (luminance);
					} else {
						alpha = 0;
					}
					bmContextSetPixel (bitmap, x, y, red, green, blue, alpha);
				}
			}
		});
	}
	
	// Wait for all tasks to complete
	dispatch_group_wait (group, DISPATCH_TIME_FOREVER);
	
	dispatch_async (dispatch_get_main_queue (), ^(void) {
		[self _dequeObjects];
		renderComplete = YES;
		if (completionBlock) {
			completionBlock (identifier == renderIdentifier);
		}
	});
}

- (void) _renderToBitmap: (BMContext *) bitmap async: (BOOL) async completion: (void (^)(BOOL success)) completionBlock {
	if (shadowContext == NULL) {
		return;
	}
	
	// Reset render queue, clear bitmap.
	[self _resetRenderQueue];
	bmContextFillBuffer (bitmap, 0, 0, 0, 255);
	
	// Compute scale.
	int width = bmContextWidth (bitmap);
	int height = bmContextHeight (bitmap);
	renderScale = 1.0;
	if ((width != shadowContext->width) || (height != shadowContext->height)) {
		renderScale = MAX ((double) width / shadowContext->width, (double) height / shadowContext->height);
	}
	
	if (async) {
		dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
			[self _renderCore: bitmap completion: completionBlock];
		});
	} else {
		[self _renderCore: bitmap completion: completionBlock];
	}
}

- (void) _kickOffRenderAndDisplay {
	[self _renderToBitmap: bitmap async: YES completion: ^(BOOL success) {
		if (success) {
			[self _displayRenderedBitmap];
			[self _generateHistogram];
			[[self overlayView] setNeedsDisplay: YES];
		}
	}];
}

- (NSInteger) _addObjectToContext: (NSString *) kind {
	NSInteger insertedRow = NSNotFound;
	int halfWidth = shadowContext->width / 2;
	int halfHeight = shadowContext->height / 2;
	newObjectAdded = YES;
	if ([kind isEqualToString: @"lamp"]) {
		int lampCount = sdContextAddLamp (shadowContext, lampCreate (halfWidth, halfHeight));
		[[self contextTableView] reloadData];
		if (lampCount > 0) {
			insertedRow = lampCount - 1;
			[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: insertedRow] byExtendingSelection: NO];
		}
	} else if ([kind isEqualToString: @"cylinder"]) {
		int obstacleCount = sdContextAddObstacle (shadowContext, obstacleCreateCylinder (halfWidth, halfHeight, 8));
		[[self contextTableView] reloadData];
		if (obstacleCount > 0) {
			int lampCount = sdContextNumberOfLamps (shadowContext);
			insertedRow = obstacleCount + lampCount - 1;
			[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: insertedRow] byExtendingSelection: NO];
		}
	} else if ([kind isEqualToString: @"rectangle"]) {
		int obstacleCount = sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (halfWidth, halfHeight, 20, 20, 0));
		[[self contextTableView] reloadData];
		
		if (obstacleCount > 0) {
			int lampCount = sdContextNumberOfLamps (shadowContext);
			insertedRow = obstacleCount + lampCount - 1;
			[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: insertedRow] byExtendingSelection: NO];
		}
	}
	
	return insertedRow;
}

- (void) _dequeObjects {
	if ((objectQueue != NULL) && ([objectQueue count] > 0)) {
		NSInteger newRow = NSNotFound;
		for (NSString *kind in objectQueue) {
			newRow = [self _addObjectToContext: kind];
		}
		[objectQueue removeAllObjects];
		if (newRow != NSNotFound) {
			[_contextTableView scrollRowToVisible: newRow];
		}
		[self _kickOffRenderAndDisplay];
	}
}

- (void) _enqueAddObject: (NSString *) kind {
	NSInteger newRow = NSNotFound;
	if (renderComplete) {
		newRow = [self _addObjectToContext: kind];
		if (newRow != NSNotFound) {
			[_contextTableView scrollRowToVisible: newRow];
		}
		[self _kickOffRenderAndDisplay];
	} else {
		if (objectQueue == NULL) {
			objectQueue = [NSMutableArray array];
		}
		[objectQueue addObject: kind];
	}
}

- (void) _createPreviewBitmapContext {
	if (bitmap) {
		bmContextFree (bitmap);
		bitmap = NULL;
	}
	
	int bitmapWidth = shadowContext->width / 10; 	// 512, 256, 128;
	int bitmapHeight = shadowContext->height / 10;	// 1024, 512, 256;
	bitmap = bmContextCreate (bitmapWidth, bitmapHeight);
}

#pragma mark - Sample contexts

- (void) test0 {
	shadowContext = sdContextCreate ("test", 1024, 2048);
	shadowContext->tempScalar = 2000;
	[self _createPreviewBitmapContext];
	[_overlayView setContextSize: NSMakeSize (1024, 2048)];
	
	sdContextAddLamp (shadowContext, lampCreate (450, 990));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (550, 1010, 10));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (380, 800, 400, 1200), 0.5));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (330, 800, 350, 950));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (330, 1050, 350, 1200), 0.5));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (500, 1200, 200, 8, -60));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (800, 1200, 820, 1200, 820, 1220, 800, 1220));
}

- (void) test1 {
	shadowContext = sdContextCreate ("test", 1024, 2048);
	shadowContext->tempScalar = 300;
	[self _createPreviewBitmapContext];
	[_overlayView setContextSize: NSMakeSize (1024, 2048)];
	
	sdContextAddLamp (shadowContext, lampCreate (256, 768));
	sdContextAddLamp (shadowContext, lampCreate (768, 768));
	sdContextAddLamp (shadowContext, lampCreate (256, 1280));
	sdContextAddLamp (shadowContext, lampCreate (768, 1280));

	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (550, 1010, 10));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (380, 800, 400, 1200), 0.5));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (330, 800, 350, 950));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (330, 1050, 350, 1200), 0.5));
}

- (void) test2 {
	shadowContext = sdContextCreate ("test", 1024, 2048);
	shadowContext->tempScalar = 3000;
	[self _createPreviewBitmapContext];
	[_overlayView setContextSize: NSMakeSize (1024, 2048)];
	
	int gap = 256;
	int divisionsX = 1024 / gap;
	int obstacleCountX = divisionsX / 2;
	int lampCountX = obstacleCountX - 1;
	int divisionsY = 2048 / gap;
	int obstacleCountY = divisionsY / 2;
	int lampCountY = obstacleCountY - 1;
	
	// Create lamps.
	double rowOffset = (1024 - ((lampCountX - 1) * 2 * gap)) / 2.0;
	double colOffset = (2048 - ((lampCountY - 1) * 2 * gap)) / 2.0;
	for (int yIndex = 0; yIndex < lampCountY; yIndex++) {
		for (int xIndex = 0; xIndex < lampCountX; xIndex++) {
			double x = rowOffset + (xIndex * gap * 2);
			double y = colOffset + (yIndex * gap * 2);
			sdContextAddLamp (shadowContext, lampCreate (x, y));
		}
	}
	
	// Create obstacles.
	rowOffset = (1024 - ((obstacleCountX - 1) * 2 * gap)) / 2.0;
	colOffset = (2048 - ((obstacleCountY - 1) * 2 * gap)) / 2.0;
	for (int yIndex = 0; yIndex < obstacleCountY; yIndex++) {
		for (int xIndex = 0; xIndex < obstacleCountX; xIndex++) {
			double x = rowOffset + (xIndex * gap * 2);
			double y = colOffset + (yIndex * gap * 2);
			sdContextAddObstacle (shadowContext, obstacleCreateCylinder (x, y, 8));
		}
	}
}

- (void) addBlueNoteLightsAndObstacles {
	shadowContext = sdContextCreate ("blue_note", 1024, 2048);
	shadowContext->version = 0;
	shadowContext->tempScalar = 100;
	[self _createPreviewBitmapContext];
	[_overlayView setContextSize: NSMakeSize (1024, 2048)];
	
	// Lights.
	sdContextAddLamp (shadowContext, lampCreate (259, 341));
	sdContextAddLamp (shadowContext, lampCreate (361, 349));
	sdContextAddLamp (shadowContext, lampCreate (464, 344));
	sdContextAddLamp (shadowContext, lampCreate (560, 348));
	sdContextAddLamp (shadowContext, lampCreate (805, 346));
	sdContextAddLamp (shadowContext, lampCreate (814, 596));
	sdContextAddLamp (shadowContext, lampCreate (777, 858));
	sdContextAddLamp (shadowContext, lampCreate (813, 953));
	sdContextAddLamp (shadowContext, lampCreate (128, 1458));
	sdContextAddLamp (shadowContext, lampCreate (167, 1565));
	sdContextAddLamp (shadowContext, lampCreate (639, 1421));
	sdContextAddLamp (shadowContext, lampCreate (687, 1321));
	sdContextAddLamp (shadowContext, lampCreate (87, 440));
	sdContextAddLamp (shadowContext, lampCreate (78, 564));
	sdContextAddLamp (shadowContext, lampCreate (72, 761));
	sdContextAddLamp (shadowContext, lampCreate (73, 777));
	sdContextAddLamp (shadowContext, lampCreate (71, 882));
	sdContextAddLamp (shadowContext, lampCreate (68, 989));
	sdContextAddLamp (shadowContext, lampCreate (72, 1098));
	sdContextAddLamp (shadowContext, lampCreate (71, 1207));
	
	// Bumpers.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (261, 600, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (449, 610, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (651, 520, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (319, 785, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (628, 725, 40));
	
	// Targets.
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (94, 563, 40, 2, -90));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (94, 671, 40, 2, -90));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (94, 776, 40, 2, -90));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (94, 879, 40, 2, -90));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (94, 988, 40, 2, -90));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (94, 1096, 40, 2, -90));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (94, 1204, 40, 2, -90));
	
	// Lanes.
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (255, 288, 265, 404), 0.75));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (355, 288, 365, 404), 0.75));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (456, 288, 466, 404), 0.75));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (552, 288, 562, 404), 0.75));

	// Posts.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (260, 289, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (260, 404, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (359, 287, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (360, 404, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (461, 287, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (461, 405, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (557, 291, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (557, 400, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (88, 343, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (93, 509, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (93, 616, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (93, 720, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (92, 827, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (91, 935, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (89, 1042, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (88, 1148, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (88, 1258, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (85, 1361, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (107, 1403, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (190, 1615, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (602, 1470, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (698, 1420, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (697, 1237, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (817, 1110, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (820, 1068, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (441, 880, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (441, 901, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (576, 881, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (576, 901, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (607, 865, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (609, 915, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (619, 8989, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (719, 991, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (729, 975, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (753, 942, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (810, 744, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (816, 708, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (820, 437, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (815, 401, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (775, 257, 8));
	
	// Blocked off left and right sides.
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (0, 0, 25, 2048));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (838, 482, 861, 2048));
	
	// Plunger lane fill lights.
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 500), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 700), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 900), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1100), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1300), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1500), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1700), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1900), 7.0));
}

- (void) addGigiLightsAndObstacles {
	shadowContext = sdContextCreate ("gigi", 1024, 2048);
	shadowContext->version = 0;
	shadowContext->tempScalar = 2000;
	shadowContext->tempOffset = 100;
	[self _createPreviewBitmapContext];
	[_overlayView setContextSize: NSMakeSize (1024, 2048)];
	
	// Lights.
	sdContextAddLamp (shadowContext, lampCreate (104, 368));
	sdContextAddLamp (shadowContext, lampCreate (772, 368));
	sdContextAddLamp (shadowContext, lampCreate (49, 620));
	sdContextAddLamp (shadowContext, lampCreate (828, 620));
	sdContextAddLamp (shadowContext, lampCreate (126, 1363));
	sdContextAddLamp (shadowContext, lampCreate (735, 1363));
	sdContextAddLamp (shadowContext, lampCreate (218, 1472));
	sdContextAddLamp (shadowContext, lampCreate (652, 1472));
	
	// Bumpers.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (435, 267, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (320, 434, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (552, 434, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (203, 598, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (441, 620, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (672, 598, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (89, 767, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (325, 793, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (550, 793, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (790, 767, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (211, 960, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (666, 960, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (89, 1145, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (790, 1145, 40));
	
	// Targets.
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (119, 394, 40, 2, -35));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (752, 395, 40, 2, 35));
	
	// Posts.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (101, 261, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (768, 261, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (157, 346, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (714, 346, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (742, 232, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (49, 417, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (826, 417, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (50, 453, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (824, 458, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (50, 683, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (824, 675, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (118, 896, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (755, 896, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (118, 995, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (755, 995, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (117, 1313, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (754, 1313, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (117, 1432, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (754, 1432, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (261, 1506, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (607, 1506, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (181, 1407, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (686, 1407, 8));
	
	// Lanes.
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (113, 896, 123, 995));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (750, 896, 760, 995));
	
	// Blocked off left and right sides.
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (0, 0, 25, 2048));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (838, 482, 861, 2048));
	
	// Plunger lane fill lights.
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 500), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 700), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 900), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1100), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1300), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1500), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1700), 7.0));
	sdContextAddLamp (shadowContext, lampSetIntensity (lampCreate (1200, 1900), 7.0));
}

#pragma mark - NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView: (NSTableView *) tableView {
	if (shadowContext == NULL) {
		return 0;
	}
	
	return sdContextNumberOfLamps (shadowContext) + sdContextNumberOfObstacles (shadowContext);
}

#pragma mark - NSTableViewDelegate

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (shadowContext == NULL) {
		return 0;
	}
	NSString *identifier = tableColumn.identifier;
	NSTableCellView *cell = [tableView makeViewWithIdentifier: identifier owner: self];
	int numLamps = sdContextNumberOfLamps (shadowContext);
	if (row >= numLamps) {
		NSInteger index = row - numLamps;
		Obstacle *obstacle = sdContextObstacleAtIndex (shadowContext, (int) index);
		switch (obstacle->kind) {
			case ObstacleKindPolygonalPrism:
			cell.textField.stringValue = [NSString stringWithFormat: @"🔷 %ld, (%ld, %ld)",
					(long) index, (long) round (obstacle->xCenter), (long) round (obstacle->yCenter)];
			break;
			
			case ObstacleKindCylinder:
			cell.textField.stringValue = [NSString stringWithFormat: @"🔵 %ld, (%ld, %ld)",
					(long) index, (long) round (obstacle->xCenter), (long) round (obstacle->yCenter)];
			break;
			
			default:	// ObstacleKindRectangularPrism
			cell.textField.stringValue = [NSString stringWithFormat: @"🟦 %ld, (%ld, %ld)",
					(long) index, (long) round (obstacle->xCenter), (long) round (obstacle->yCenter)];
			break;
		}
	} else {
		Lamp *lamp = sdContextLampAtIndex (shadowContext, (int) row);
		cell.textField.stringValue = [NSString stringWithFormat: @"💡 %ld, (%ld, %ld)",
				(long) row, (long) round (lamp->xLoc), (long) round (lamp->yLoc)];
	}
	return cell;
}

- (void) tableViewSelectionDidChange :(NSNotification *) notification {
	if ([notification object] == _contextTableView) {
		NSInteger selectedRow = [_contextTableView selectedRow];
		[_overlayView clearCrossHair];
		if (selectedRow != NSNotFound) {
			NSPoint center;
			if (selectedRow < sdContextNumberOfLamps (shadowContext)) {
				Lamp *lamp = sdContextLampAtIndex (shadowContext, (int) selectedRow);
				if (lamp) {
					center.x = lamp->xLoc;
					center.y = lamp->yLoc;
					[_overlayView setCrosshair: center];
				}
			} else {
				int index = (int) selectedRow - sdContextNumberOfLamps (shadowContext);
				Obstacle *obstacle = sdContextObstacleAtIndex (shadowContext, index);
				if (obstacle) {
					center.x = obstacle->xCenter;
					center.y = obstacle->yCenter;
					[_overlayView setCrosshair: center];
				}
			}
		}
		[self _captureTextFieldEditor];
		[self _showDetailForObjectAtIndex: selectedRow];
		wasSelectedRow = selectedRow;
		if (newObjectAdded) {
			NSTabViewItem *currentTabViewItem = [_detailTabView selectedTabViewItem];
			NSView *currentTabViewItemView = currentTabViewItem.view;
			NSView *firstKeyView = [currentTabViewItemView nextKeyView];
			[firstKeyView becomeFirstResponder];
			newObjectAdded = NO;
		}
	}
}

#pragma mark - NSTextFieldDelegate

- (void) controlTextDidEndEditing: (NSNotification *) obj {
	if (shadowContext == NULL) {
		return;
	}
	
	NSInteger tag = [[obj object] tag];
	if (tag == -1) {
		int newScalar = [[obj object] intValue];
		if (shadowContext->tempScalar != newScalar) {
			shadowContext->tempScalar = newScalar;
			[self _kickOffRenderAndDisplay];
		}
	} else if (tag == -2) {
		int newOffset = [[obj object] intValue];
		if (shadowContext->tempOffset != newOffset) {
			shadowContext->tempOffset = newOffset;
			[self _kickOffRenderAndDisplay];
		}
	} else {
		NSInteger row = [_contextTableView selectedRow];
		if (row >= 0) {
			BOOL changed = [self _takeDataFromTextField: [obj object]];
			[[self contextTableView] reloadData];
			[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row] byExtendingSelection: NO];
			if (changed) {
				[self _kickOffRenderAndDisplay];
			}
		}
	}
}

#pragma mark - App Delegate

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	
	CGRect frame = _shadowImageView.frame;
	_overlayView = [[OverlayView alloc] initWithFrame: frame];
	[_overlayView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[[_shadowImageView superview] addSubview: _overlayView positioned: NSWindowAbove relativeTo: _shadowImageView];
	
//	[self test0];
//	[self test1];
//	[self test2];
//	[self addBlueNoteLightsAndObstacles];
//	[self addGigiLightsAndObstacles];
//	[self addBaseballLightsAndObstacles];
	
//	[[self contextTableView] reloadData];
//	[self _kickOffRenderAndDisplay];
}

- (void) applicationWillTerminate: (NSNotification *) aNotification {
	// Insert code here to tear down your application
}

- (BOOL) applicationSupportsSecureRestorableState: (NSApplication *) app {
	return YES;
}

#pragma mark - Actions

- (IBAction) newContext: (id) sender {
	[NSApp runModalForWindow: _contextWindow];
}

- (IBAction) newContextOKAction: (id) sender {
	NSString *name = [_contextNameTextField stringValue];
	NSInteger width = [_contextWidthTextField integerValue];
	if (width < 128) {
		width = 128;
	} else if (width > 1024) {
		width = 1024;
	}
	NSInteger height = [_contextHeightTextField integerValue];
	if (height < 128) {
		height = 128;
	} else if (height > 2048) {
		height = 2048;
	}
	
	if (shadowContext) {
		sdContextFree (shadowContext);
		shadowContext = NULL;
	}
	
	shadowContext = sdContextCreate ((char *) name.UTF8String, (int) width, (int) height);
	shadowContext->version = 0;
	shadowContext->tempScalar = 100;
	[self _createPreviewBitmapContext];
	[_overlayView setContextSize: NSMakeSize (width, height)];
	[[self contextTableView] reloadData];
	[self _kickOffRenderAndDisplay];
	[_value1TextField setIntValue: shadowContext->tempScalar];
	[_value2TextField setIntValue: shadowContext->tempOffset];
	
	// Close the dialog
	[NSApp stopModal];
	[_contextWindow close];
}

- (IBAction) newContextCancelAction: (id) sender {
	// Close the dialog
	[NSApp stopModal];
	[_contextWindow close];
}

- (IBAction) tempSlider: (id) sender {
	shadowContext->tempScalar = [sender intValue];
	[self _kickOffRenderAndDisplay];
}

- (IBAction) tempSlider2: (id) sender {
	shadowContext->tempOffset = [sender intValue];
	[self _kickOffRenderAndDisplay];
}

- (IBAction) addLampAction: (id) sender {
	if (shadowContext) {
		[self _enqueAddObject: @"lamp"];
	}
}

- (IBAction) addCylindricalObstacleAction: (id) sender {
	if (shadowContext) {
		[self _enqueAddObject: @"cylinder"];
	}
}

- (IBAction) addRectangularObstacleAction: (id) sender {
	if (shadowContext) {
		[self _enqueAddObject: @"rectangle"];
	}
}

- (IBAction) deleteLampObstacleAction: (id) sender {
	NSInteger selectedRow = [_contextTableView selectedRow];
	if ((shadowContext)  && (selectedRow >= 0)) {
		int numberOfLamps = sdContextNumberOfLamps (shadowContext);
		if (selectedRow < numberOfLamps) {
			sdContextRemoveLampAtIndex (shadowContext, (int) selectedRow);
		} else {
			sdContextRemoveObstacleAtIndex (shadowContext, (int) selectedRow - numberOfLamps);
		}
		[[self contextTableView] reloadData];
	}
}

- (IBAction) openJSONRepresentation: (id) sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	openPanel.allowsMultipleSelection = NO;
	[openPanel setAllowedContentTypes: [NSArray arrayWithObject: [UTType typeWithIdentifier: @"com.softdorothy.shadowdrome-document"]]];
	[openPanel beginWithCompletionHandler:^ (NSInteger result) {
		if (result == NSModalResponseOK) {
			for (NSURL *oneURL in [openPanel URLs]) {
				NSError *error;
				NSString *json = [NSString stringWithContentsOfURL: oneURL encoding: NSASCIIStringEncoding error: &error];
				if (json) {
					if (shadowContext) {
						sdContextFree (shadowContext);
						shadowContext = NULL;
					}
					shadowContext = sdContextCreateFromJSONRepresentation ([json cStringUsingEncoding: NSASCIIStringEncoding]);
					[self _createPreviewBitmapContext];
					[[self overlayView] setContextSize: NSMakeSize (shadowContext->width, shadowContext->height)];
					wasSelectedRow = -1;
					[[self contextTableView] reloadData];
					[self _kickOffRenderAndDisplay];
					[[self value1TextField] setIntValue: shadowContext->tempScalar];
					[[self value2TextField] setIntValue: shadowContext->tempOffset];
				}
			}
		}
	}];
}

- (IBAction) saveJSONRepresentation: (id) sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	
	// Set the allowed content types, default filename.
	[panel setAllowedContentTypes: [NSArray arrayWithObject: [UTType typeWithIdentifier: @"com.softdorothy.shadowdrome-document"]]];
	panel.nameFieldStringValue = [NSString stringWithFormat: @"%s", shadowContext->name];
	[panel beginWithCompletionHandler: ^(NSModalResponse result) {
		if (result == NSModalResponseOK) {
			NSString *json = [NSString stringWithCString: sdContextJSONRepresentation (shadowContext) encoding: NSASCIIStringEncoding];
			if (json) {
				NSError *error;
				[json writeToURL: [panel URL] atomically: YES encoding: NSUTF8StringEncoding error: &error];
			}
		}
	}];
}

- (IBAction) saveBitmap: (id) sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setAllowedContentTypes: [NSArray arrayWithObject: UTTypePNG]];
	panel.nameFieldStringValue = [NSString stringWithFormat: @"%s_shadows", shadowContext->name];
	[panel beginWithCompletionHandler: ^(NSModalResponse result) {
		if (result == NSModalResponseOK) {
			[self _writeFullsizeBitmapDataToURL: [panel URL]];
		}
	}];
}

@end
