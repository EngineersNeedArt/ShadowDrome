//
//  ShadowContext.h
//

#ifndef ShadowContext_h
#define ShadowContext_h

#include <stdio.h>
#include "BitmapContext.h"
#include "Lamp.h"
#include "Obstacle.h"


typedef struct {
	char *name;
	int width;
	int height;
	int lampCount;
	Lamp *lampArray;
	int obstacleCount;
	Obstacle *obstacleArray;
	int tempScalar;
} SDContext;

/// Create a context with specified width and height.
SDContext *sdContextCreate (char *name, int width, int height);

/// Add lamp to context. Caller should not free lamp until after context is freed - context only has pointer to lamp.
/// Returns count of lamps.
int sdContextAddLamp (SDContext *context, Lamp *lamp);

/// Add obstacle to context. Caller should not free obstacle until after context is freed - context only has pointer to obstacle.
/// Returns count of obstacles.
int sdContextAddObstacle (SDContext *context, Obstacle *obstacle);

/// Renders pixel data to bitmap. If bitmap width and height do not match context width and height, context will apply scale to fit when rendering.
/// Bitmap is an RGBA, 8-bit bitmap. RGB values of bitmap pixels remain unchanged by this operation, alpha component for each pixel though
/// will represent the luminosity at each point.
/// Returns 1 on success.
int sdContextRenderToBitmap (SDContext *context, BMContext *bitmap);

#endif /* ShadowContext_h */
