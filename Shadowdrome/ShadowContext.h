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
	int width;
	int height;
	int lampCount;
	Lamp *lampArray;
	int obstacleCount;
	Obstacle *obstacleArray;
	int tempScalar;
} SDContext;

SDContext *sdContextCreate (int width, int height);

int sdContextAddLamp (SDContext *context, Lamp *lamp);

int sdContextAddObstacle (SDContext *context, Obstacle *obstacle);

int sdContextRenderToBitmap (SDContext *context, BMContext *bitmap);

#endif /* ShadowContext_h */
