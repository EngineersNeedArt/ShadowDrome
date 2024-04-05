//
//  AppDelegate.m
//  Shadowdrome
//
//  Created by John Calhoun on 3/7/24.
//

#import "AppDelegate.h"
#include "BitmapContext.h"
#include "Lamp.h"
#include "Obstacle.h"
#include "ShadowContext.h"
#include "ShadowContextJSONLayer.h"


@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSImageView *shadowImageView;
@property (strong) IBOutlet NSTableView *contextTableView;
@property (strong) IBOutlet NSTabView *detailTabView;

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

@property (strong) NSString *contextJSON;
@end

@implementation AppDelegate

BMContext *bitmap;
SDContext *shadowContext;
BOOL newLampAdded = NO;
NSInteger wasSelectedRow = -1;
BOOL renderComplete = NO;
NSInteger nextRenderX = 0;
NSInteger nextRenderY = 0;
NSInteger renderIdentifier = -1;
NSMutableArray<dispatch_queue_t> *workerQueues;
double renderScale = 1.0;

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

- (void) _takeDataFromTextField: (NSTextField *) textField {
	NSInteger tag = [textField tag];
	NSInteger index = wasSelectedRow;
	if (index >= sdContextNumberOfLamps (shadowContext)) {
		index -= sdContextNumberOfLamps (shadowContext);
		Obstacle *obstacle = sdContextObstacleAtIndex (shadowContext, (int) index);
		switch (tag) {
			case 0:
			if (obstacle->xCenter == round ([textField doubleValue])) {
				return;
			}
			obstacleSetXY (obstacle, round ([textField doubleValue]), obstacle->yCenter);
			break;
			
			case 1:
			if (obstacle->yCenter == round ([textField doubleValue])) {
				return;
			}
			obstacleSetXY (obstacle, obstacle->xCenter, round ([textField doubleValue]));
			break;
			
			case 2:
			if (obstacle->radius == round ([textField doubleValue])) {
				return;
			}
			obstacleSetRadius (obstacle, round ([textField doubleValue]));
			break;
			
			case 3:
			if (obstacle->rotationDegrees == [textField doubleValue]) {
				return;
			}
			obstacleSetRotationDegrees (obstacle, [textField doubleValue]);
			break;
			
			case 4:
			if (obstacle->width == round ([textField doubleValue])) {
				return;
			}
			obstacleSetWidth (obstacle, round ([textField doubleValue]));
			break;
			
			case 5:
			if (obstacle->height == round ([textField doubleValue])) {
				return;
			}
			obstacleSetHeight (obstacle, round ([textField doubleValue]));
			break;
			
			case 6:
			if (obstacle->opacity == [textField doubleValue]) {
				return;
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
				return;
			}
			lamp->xLoc = round ([textField doubleValue]);
			break;
			
			case 1:
			if (lamp->yLoc == round ([textField doubleValue])) {
				return;
			}
			lamp->yLoc = round ([textField doubleValue]);
			break;
			
			case 2:
			if (lamp->radius == round ([textField doubleValue])) {
				return;
			}
			lamp->radius = round ([textField doubleValue]);
			break;
			
			case 3:
			if (lamp->intensity == round ([textField doubleValue])) {
				return;
			}
			lamp->intensity = round ([textField doubleValue]);
			break;
			
			default:
			break;
		}
	}
}

- (void) _capture {
	NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSResponder *currentResponder = [keyWindow firstResponder];
	if ([currentResponder isKindOfClass: [NSTextView class]]) {
		NSTextField *textField = [self _findOwningTextFieldFromTextView: (NSTextView *) currentResponder];
		if ([textField currentEditor] != NULL) {
			[self _takeDataFromTextField: textField];
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

- (NSData *) _getFullsizeBitmapData {
	NSData *bitmapData = NULL;
	BMContext *fullBitmap;
	
	fullBitmap = bmContextCreate (1024, 2048);
//	fullBitmap = bmContextCreate (2048, 4096);
	bmContextFillBuffer (fullBitmap, 0, 0, 0, 255);
	sdContextRenderToBitmap (shadowContext, fullBitmap);
	
	CGDataProviderRef provider = CGDataProviderCreateWithData (NULL, bmContextBufferPtr(fullBitmap), bmContextBufferSize(fullBitmap), NULL);
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
	
	return bitmapData;
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

- (void) _renderPlayfield0 {
	bmContextFillBuffer (bitmap, 0, 0, 0, 255);
	sdContextRenderToBitmap (shadowContext, bitmap);
	
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

- (void) _renderPlayfield1 {
	// Reset render queue, clear bitmap.
	[self _resetRenderQueue];
	bmContextFillBuffer (bitmap, 0, 0, 0, 255);
	
	dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		int width = bmContextWidth (bitmap);
		int height = bmContextHeight (bitmap);
		renderScale = 1.0;
		if ((width != shadowContext->width) || (height != shadowContext->height)) {
			renderScale = MAX ((double) width / shadowContext->width, (double) height / shadowContext->height);
		}
		
		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
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
		
		dispatch_async (dispatch_get_main_queue (), ^(void) {
			[self _displayRenderedBitmap];
		});
	});
}

- (void) _renderPlayfield {
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
	
	dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		// Create a dispatch group to keep track of completion
		dispatch_group_t group = dispatch_group_create ();
		
		// Iterate through each pixel in the bitmap and dispatch tasks to the worker queues.
		NSInteger identifier = renderIdentifier;
		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				dispatch_group_async (group, [workerQueues objectAtIndex: x % 8], ^{
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
				});
			}
		}
		
		// Wait for all tasks to complete
		dispatch_group_wait (group, DISPATCH_TIME_FOREVER);
		
		dispatch_async (dispatch_get_main_queue (), ^(void) {
			[self _displayRenderedBitmap];
		});
	});
}

#pragma mark - Sample contexts

- (void) test0 {
	shadowContext = sdContextCreate ("test", 1024, 2048);
	shadowContext->tempScalar = 2000;
	
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

- (void) addBaseballLightsAndObstacles {
	shadowContext = sdContextCreate ("baseball", 1024, 2048);
	shadowContext->version = 0;
	shadowContext->tempScalar = 75;
	shadowContext->tempOffset = 0;
	
	// Lights.
	sdContextAddLamp (shadowContext, lampCreate (67, 430));
	sdContextAddLamp (shadowContext, lampCreate (800, 418));
	sdContextAddLamp (shadowContext, lampCreate (90, 671));
	sdContextAddLamp (shadowContext, lampCreate (431, 690));
	sdContextAddLamp (shadowContext, lampCreate (774, 672));
	sdContextAddLamp (shadowContext, lampCreate (278, 350));
	sdContextAddLamp (shadowContext, lampCreate (382, 348));
	sdContextAddLamp (shadowContext, lampCreate (480, 348));
	sdContextAddLamp (shadowContext, lampCreate (575, 347));
	sdContextAddLamp (shadowContext, lampCreate (116, 897));
	sdContextAddLamp (shadowContext, lampCreate (742, 892));
	sdContextAddLamp (shadowContext, lampCreate (127, 1029));
	sdContextAddLamp (shadowContext, lampCreate (739, 1024));
	sdContextAddLamp (shadowContext, lampCreate (167, 1318));
	sdContextAddLamp (shadowContext, lampCreate (693, 1318));
	sdContextAddLamp (shadowContext, lampCreate (217, 1437));
	sdContextAddLamp (shadowContext, lampCreate (644, 1436));
	
	// Bumpers.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (244, 525, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (616, 525, 40));

	// Targets.
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (142, 1047, 40, 2, -40));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (719, 1047, 40, 2, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (386, 707, 40, 2, 45));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (475, 707, 40, 2, -45));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (238, 991, 40, 2, -23.5));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (623, 991, 40, 2, 23.5));
	
	// Posts.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (278, 299, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (382, 299, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (479, 299, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (573, 299, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (278, 375, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (382, 375, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (479, 375, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (573, 375, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (47, 465, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (113, 359, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (759, 320, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (816, 460, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (430, 512, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (360, 664, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (500, 664, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (430, 737, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (49, 495, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (811, 495, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (152, 662, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (713, 662, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (45, 750, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (819, 750, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (212, 770, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (649, 770, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (104, 857, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (757, 857, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (291, 959, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (568, 959, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (183, 1014, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (679, 1014, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (101, 1075, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (758, 1075, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (41, 1161, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (819, 1161, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (152, 1248, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (710, 1248, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (154, 1418, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (707, 1418, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (258, 1478, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (603, 1478, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (200, 1363, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (659, 1363, 8));
	
	// Lanes.
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (273, 299, 283, 375));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (377, 299, 387, 375));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (474, 299, 484, 375));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (569, 299, 579, 375));
	
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
		[self _capture];
		[self _showDetailForObjectAtIndex: selectedRow];
		wasSelectedRow = selectedRow;
		if (newLampAdded) {
			NSTabViewItem *currentTabViewItem = [_detailTabView selectedTabViewItem];
			NSView *currentTabViewItemView = currentTabViewItem.view;
			NSView *firstKeyView = [currentTabViewItemView nextKeyView];
			[firstKeyView becomeFirstResponder];
			newLampAdded = NO;
		}
	}
}

#pragma mark - NSTextFieldDelegate

- (void) controlTextDidEndEditing: (NSNotification *) obj {
	if (shadowContext == NULL) {
		return;
	}
	NSInteger row = [_contextTableView selectedRow];
	if (row >= 0) {
		[self _takeDataFromTextField: [obj object]];
		[[self contextTableView] reloadData];
		[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row] byExtendingSelection: NO];
		[self _renderPlayfield];
	}
}

#pragma mark - App Delegate

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	// Create array of eight background queues.
	workerQueues = [NSMutableArray arrayWithCapacity: 8];
	for (int i = 0; i < 8; i++) {
		dispatch_queue_t queue = dispatch_queue_create ([[NSString stringWithFormat: @"com.shadowdrome.queue%d", i + 1] UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
		[workerQueues addObject: queue];
	}
	
	// Create bitmap context.
	int bitmapWidth = 128; 	// 512, 256;
	int bitmapHeight = 256;	// 1024, 512;
	bitmap = bmContextCreate (bitmapWidth, bitmapHeight);
	
//	[self test0];
//	[self test1];
//	[self test2];
//	[self addBlueNoteLightsAndObstacles];
//	[self addGigiLightsAndObstacles];
//	[self addBaseballLightsAndObstacles];
	
	[[self contextTableView] reloadData];
	[self _renderPlayfield];
}

- (void) applicationWillTerminate: (NSNotification *) aNotification {
	// Insert code here to tear down your application
}

- (BOOL) applicationSupportsSecureRestorableState: (NSApplication *) app {
	return YES;
}

#pragma mark - Actions

- (IBAction) newContext: (id) sender {
	if (shadowContext) {
		sdContextFree (shadowContext);
		shadowContext = NULL;
	}
	shadowContext = sdContextCreate ("temp", 1024, 2048);
	shadowContext->version = 0;
	shadowContext->tempScalar = 100;
	[[self contextTableView] reloadData];
	[self _renderPlayfield];
}

- (IBAction) tempSlider: (id) sender {
	shadowContext->tempScalar = [sender intValue];
	[self _renderPlayfield];
}

- (IBAction) tempSlider2: (id) sender {
	shadowContext->tempOffset = [sender intValue];
	[self _renderPlayfield];
}

- (IBAction) addLampAction: (id) sender {
	if (shadowContext) {
		newLampAdded = YES;
		int lampCount = sdContextAddLamp (shadowContext, lampCreate (512, 1024));
		[[self contextTableView] reloadData];
		if (lampCount > 0) {
			[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: lampCount - 1] byExtendingSelection: NO];
		}
	}
}

- (IBAction) addCylindricalObstacleAction: (id) sender {
	if (shadowContext) {
		int obstacleCount = sdContextAddObstacle (shadowContext, obstacleCreateCylinder (512, 1024, 8));
		[[self contextTableView] reloadData];
		
		if (obstacleCount > 0) {
			int lampCount = sdContextNumberOfLamps (shadowContext);
			[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: obstacleCount + lampCount - 1] byExtendingSelection: NO];
		}
	}
}

- (IBAction) addRectangularObstacleAction: (id) sender {
	if (shadowContext) {
		int obstacleCount = sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (512, 1024, 20, 20, 0));
		[[self contextTableView] reloadData];
		
		if (obstacleCount > 0) {
			int lampCount = sdContextNumberOfLamps (shadowContext);
			[_contextTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: obstacleCount + lampCount - 1] byExtendingSelection: NO];
		}
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
					wasSelectedRow = -1;
					[[self contextTableView] reloadData];
					[self _renderPlayfield];
				}
			}
		}
	}];
}

- (IBAction) saveJSONRepresentation: (id) sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.nameFieldStringValue = [NSString stringWithFormat: @"%s.shadow", shadowContext->name];
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
	panel.nameFieldStringValue = [NSString stringWithFormat: @"%s_shadows.png", shadowContext->name];
	[panel beginWithCompletionHandler: ^(NSModalResponse result) {
		if (result == NSModalResponseOK) {
			NSData *bitmapData = [self _getFullsizeBitmapData];
			if (bitmapData) {
				[bitmapData writeToURL: [panel URL] atomically: YES];
			}
		}
	}];
}

@end
