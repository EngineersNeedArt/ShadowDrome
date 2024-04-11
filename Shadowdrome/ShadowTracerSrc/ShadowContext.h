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
	int version;
	char *name;
	int width;
	int height;
	int lampCount;
	Lamp *lampArray;
	int obstacleCount;
	Obstacle *obstacleArray;
	int tempScalar;
	int tempOffset;
} SDContext;

/// Create a context with specified width and height.
SDContext *sdContextCreate (char *name, int width, int height);

/// Add lamp to context. Caller should not free lamp - context has pointer to lamp, will free when context is freed.
/// Returns count of lamps.
int sdContextAddLamp (SDContext *context, Lamp *lamp);

/// Remove lamp with index from context. Will return (-1) if error, otherwise returns new count of lamps.
int sdContextRemoveLampAtIndex (SDContext *context, int index);

int sdContextNumberOfLamps (SDContext *context);

Lamp *sdContextLampAtIndex (SDContext *context, int index);

/// Add obstacle to context. Caller should not free obstacle - context has pointer to obstacle, will free when context is freed.
/// Returns count of obstacles.
int sdContextAddObstacle (SDContext *context, Obstacle *obstacle);

/// Remove obstacle with index from context. Will return (-1) if error, otherwise returns new count of obstacles.
int sdContextRemoveObstacleAtIndex (SDContext *context, int index);

int sdContextNumberOfObstacles (SDContext *context);

Obstacle *sdContextObstacleAtIndex (SDContext *context, int index);

double sdContextGetLuminanceForPoint (SDContext *context, double x, double y);

/// Renders pixel data to bitmap. If bitmap width and height do not match context width and height, context will apply scale to fit when rendering.
/// Bitmap is an RGBA, 8-bit bitmap. RGB values of bitmap pixels remain unchanged by this operation, alpha component for each pixel though
/// will represent the luminosity at each point.
/// Returns 1 on success.
int sdContextRenderToBitmap (SDContext *context, BMContext *bitmap);

#endif /* ShadowContext_h */

void sdContextFree (SDContext *context);
