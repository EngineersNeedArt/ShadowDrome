//
//  ShadowContext.c
//


#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "ShadowContext.h"


#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

#pragma mark - Private

int _sdCCW (double x0, double y0, double x1, double y1, double x2, double y2) {
	return ((y2 - y0) * (x1 - x0)) > ((y1 - y0) * (x2 - x0));
}

int _sdIntersects (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3) {
	return (_sdCCW (x0, y0, x2, y2, x3, y3) != _sdCCW (x1, y1, x2, y2, x3, y3)) &&
			(_sdCCW (x0, y0, x1, y1, x2, y2) != _sdCCW (x0, y0, x1, y1, x3, y3));
}

int _sdIntersects2 (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3) {
	double dx0 = x1 - x0;
	double dx1 = x3 - x2;
	double dy0 = y1 - y0;
	double dy1 = y3 - y2;
	double p0 = dy1 * (x3 - x0) - dx1 * (y3 - y0);
	double p1 = dy1 * (x3 - x1) - dx1 * (y3 - y1);
	double p2 = dy0 * (x1 - x2) - dx0 * (y1 - y2);
	double p3 = dy0 * (x1 - x3) - dx0 * (y1 - y3);
	return ((p0 * p1) <= 0) & ((p2 * p3) <= 0);
}

// A relative pixel x and y are passed in as is the lamp. Returns normalX and normalY.
// The normal is perpendicular to the line connecting the pixel to the lamp center.
// The normal is scaled to the lamp radius.

void _sdLampNormal (double pixelX, double pixelY, Lamp *lamp, double *normalX, double *normalY) {
	double dX = pixelX - lamp->xLoc;
	double dY = pixelY - lamp->yLoc;
	double distance = sqrt ((dX * dX) + (dY * dY));
	double scale = lamp->radius / distance;
	*normalX = -dY * scale;
	*normalY = dX * scale;
}

int _sdPointIsInPolygon (double x, double y, int numVertices, double *vertices) {
	double *vertexPtr = vertices;
	double zeroVertexX = *vertexPtr;
	vertexPtr++;
	double zeroVertexY = *vertexPtr;
	vertexPtr++;
	double prevVertexX = zeroVertexX;
	double prevVertexY = zeroVertexY;
	
	int inside = 0;
	for (int i = 1; i < numVertices; i++) {
		double vertexX = *vertexPtr;
		vertexPtr++;
		double vertexY = *vertexPtr;
		vertexPtr++;
		if ((vertexY > y) != (prevVertexY > y) && x < (prevVertexX - vertexX) * (y - vertexY) / (prevVertexY - vertexY) + vertexX) {
			inside = 1 - inside;
		}
		prevVertexX = vertexX;
		prevVertexY = vertexY;
	}
	
	// Test wrap-around vertex.
	if ((zeroVertexY > y) != (prevVertexY > y) && x < (prevVertexX - zeroVertexX) * (y - zeroVertexY) / (prevVertexY - zeroVertexY) + zeroVertexX) {
		inside = 1 - inside;
	}
	
	return inside;
}

int _sdPointInObstacle (double x, double y, Obstacle *obstacle) {
	if ((x < obstacle->minX) || (x > obstacle->maxX) || (y < obstacle->minY) || (y > obstacle->maxY)) {
		return 0;
	}
	
	if (_sdPointIsInPolygon (x, y, obstacle->numVertices, obstacle->vertexArray)) {
		return 1;
	}
	
	return 0;
}

// Returns [0.0 (no obstacle) ... 1.0 (light fully blocked)].

double _sdTestTotalObstacleOpacity (SDContext *context, double x0, double y0, double x1, double y1) {
	bool isObstacle = false;
	double transparency = 1.0;
	Obstacle *obstaclePtr = context->obstacleArray;
	for (int o = 0; o < context->obstacleCount; o++) {
		if (obstaclePtr->opacity == 0.0) {
			obstaclePtr++;
			continue;
		}
		double *vertexPtr = obstaclePtr->vertexArray;
		double xOrig = *vertexPtr;
		vertexPtr++;
		double yOrig = *vertexPtr;
		vertexPtr++;
		double prevX = xOrig;
		double prevY = yOrig;
		for (int v = 1; v < obstaclePtr->numVertices; v++) {
			double nextX = *vertexPtr;
			vertexPtr++;
			double nextY = *vertexPtr;
			vertexPtr++;
			if (_sdIntersects2 (x0, y0, x1, y1, prevX, prevY, nextX, nextY)) {
				isObstacle = true;
				if (obstaclePtr->opacity < 1.0) {
					transparency = transparency * (1.0 - obstaclePtr->opacity);
					break;
				} else {
					return 1.0;
				}
			}
			prevX = nextX;
			prevY = nextY;
		}
		if (_sdIntersects2 (x0, y0, x1, y1, prevX, prevY, xOrig, yOrig)) {
			isObstacle = true;
			if (obstaclePtr->opacity < 1.0) {
				transparency = transparency * (1.0 - obstaclePtr->opacity);
				break;
			} else {
				return 1.0;
			}
		}
		obstaclePtr++;
	}
	
	if (isObstacle) {
		return 1.0 - transparency;
	} else {
		return 0.0;
	}
}

void _sdGetFilamentPointForLamp (Lamp *lamp, double relX, double relY, double distance, double *xLoc, double *yLoc) {
	double normalX, normalY;
	_sdLampNormal (relX, relY, lamp, &normalX, &normalY);
	if (xLoc) {
		double deltaX = normalX * (distance / lamp->radius);
		*xLoc = lamp->xLoc + deltaX;
	}
	if (yLoc) {
		double deltaY = normalY * (distance / lamp->radius);
		*yLoc = lamp->yLoc + deltaY;
	}
}

double _sdMapIntensity (SDContext *context, double distanceSquared, double intensity) {
	if (0) {
    	return (intensity * (double) context->tempScalar) / (distanceSquared + 10000);
	} else {
    	double distance = sqrt (distanceSquared) + (double) context->tempOffset;
    	return (intensity * (double) context->tempScalar) / (distance * distance);
	}
//	double distance = sqrt (distanceSquared) / 10;
//	return (intensity * 100000) / ((distance + 100) * (distance + 100));
//	return (intensity * 500) / (distance * distance);
}

double _sdLuminanceForLamp (SDContext *context, double x, double y, Lamp *lamp) {
	double luminance = 0.0;
	int sampleCount = round (lamp->radius);
	for (int i = 0; i <= sampleCount + 1; i++) {
		double filamentDistance = (i * 2) - lamp->radius;
		double filamentIntensity = fabs (filamentDistance / lamp->radius) * lamp->intensity;
		double xLoc, yLoc;
		_sdGetFilamentPointForLamp (lamp, x, y, filamentDistance, &xLoc, &yLoc);
		double opacity = _sdTestTotalObstacleOpacity (context, x, y, xLoc, yLoc);
		if (opacity < 1.0) {
			double xDistance = xLoc - x;
			double yDistance = yLoc - y;
			double distanceSquared = (xDistance * xDistance) + (yDistance * yDistance);
			if (distanceSquared != 0.0) {
				double intensity = _sdMapIntensity (context, distanceSquared, filamentIntensity);
				luminance += (intensity * (1.0 - opacity));
			}
		}
	}
	
	if (1) {
		luminance  = luminance / (double) sampleCount;
	}
	
	return luminance;
}

double _sdContextGetLuminanceForPoint (SDContext *context, double x, double y) {
	double luminance = 0.0;
	
	Obstacle *obstaclePtr = context->obstacleArray;
	for (int o = 0; o < context->obstacleCount; o++) {
		if (_sdPointInObstacle (x, y, obstaclePtr)) {
			if (obstaclePtr->opacity == 0.0) {
				return 1.0;
			}
			return 0.0;
//			return obstaclePtr->opacity;
		}
		obstaclePtr++;
	}
	
	Lamp *lampPtr = context->lampArray;
	for (int l = 0; l < context->lampCount; l++) {
		luminance += _sdLuminanceForLamp (context, x, y, lampPtr);
//		luminance = (luminance + _sdLuminanceForLamp (context, x, y, lampPtr)) / 2.0;
		lampPtr++;
	}
	return luminance;
}

#pragma mark - Public

SDContext *sdContextCreate (char *name, int width, int height) {
	SDContext *context = malloc (sizeof (SDContext));
	context->name = malloc (sizeof (char) * (strlen (name) + 1));
	context->name[0] = '\0';
	strcpy (context->name, name);
	context->width = width;
	context->height = height;
	context->lampCount = 0;
	context->lampArray = NULL;
	context->obstacleCount = 0;
	context->obstacleArray = NULL;
	
	context->tempScalar = 200;
	context->tempOffset = 0;
	
	return context;
}

int sdContextAddLamp (SDContext *context, Lamp *lamp) {
	// Param check.
	if (context == NULL) {
		return 0;
	}
	
	Lamp *wasLampArray = context->lampArray;
	context->lampArray = malloc(sizeof (Lamp) * (context->lampCount + 1));
	
	Lamp *srcLampPtr = wasLampArray;
	Lamp *destLampPtr = context->lampArray;
	for (int i = 0; i < context->lampCount; i++) {
		*destLampPtr = *srcLampPtr;
		srcLampPtr++;
		destLampPtr++;
	}
	
	*destLampPtr = *lamp;
	context->lampCount = context->lampCount + 1;
	
	if (wasLampArray) {
		free (wasLampArray);
	}
	
	return context->lampCount;
}

int sdContextRemoveLampAtIndex (SDContext *context, int index) {
	// Param check.
	if ((context == NULL) || (index < 0) || (index >= context->lampCount)) {
		return -1;
	}
	
	Lamp *wasLampArray = context->lampArray;
	context->lampArray = malloc (sizeof (Lamp) * (context->lampCount - 1));
	
	Lamp *srcLampPtr = wasLampArray;
	Lamp *destLampPtr = context->lampArray;
	for (int i = 0; i < context->lampCount; i++) {
		if (i != index) {
			*destLampPtr = *srcLampPtr;
			destLampPtr++;
		}
		srcLampPtr++;
	}
	
	context->lampCount = context->lampCount - 1;
	
	if (wasLampArray) {
		free (wasLampArray);
	}
	
	return context->lampCount;
}

int sdContextNumberOfLamps (SDContext *context) {
	// Param check.
	if (context == NULL) {
		return 0;
	}
	return context->lampCount;
}

Lamp *sdContextLampAtIndex (SDContext *context, int index) {
	// Param check.
	if ((context == NULL) || (index < 0) || (index >= context->lampCount)) {
		return NULL;
	}
	return &(context->lampArray[index]);
}

int sdContextAddObstacle (SDContext *context, Obstacle *obstacle) {
	// Param check.
	if (context == NULL) {
		return 0;
	}
	
	Obstacle *wasObstacleArray = context->obstacleArray;
	context->obstacleArray = malloc(sizeof (Obstacle) * (context->obstacleCount + 1));
	
	Obstacle *srcObstaclePtr = wasObstacleArray;
	Obstacle *destObstaclePtr = context->obstacleArray;
	for (int i = 0; i < context->obstacleCount; i++) {
		*destObstaclePtr = *srcObstaclePtr;
		srcObstaclePtr++;
		destObstaclePtr++;
	}
	
	*destObstaclePtr = *obstacle;
	context->obstacleCount = context->obstacleCount + 1;
	
	if (wasObstacleArray) {
		free (wasObstacleArray);
	}
	
	return context->obstacleCount;
}

int sdContextRemoveObstacleAtIndex (SDContext *context, int index) {
	// Param check.
	if ((context == NULL) || (index < 0) || (index >= context->obstacleCount)) {
		return -1;
	}
	
	Obstacle *wasObstacleArray = context->obstacleArray;
	context->obstacleArray = malloc (sizeof (Obstacle) * (context->obstacleCount - 1));
	
	Obstacle *srcObstaclePtr = wasObstacleArray;
	Obstacle *destObstaclePtr = context->obstacleArray;
	for (int i = 0; i < context->obstacleCount; i++) {
		if (i != index) {
			*destObstaclePtr = *srcObstaclePtr;
			destObstaclePtr++;
		}
		srcObstaclePtr++;
	}
	
	context->obstacleCount = context->obstacleCount - 1;
	
	if (wasObstacleArray) {
		free (wasObstacleArray);
	}
	
	return context->obstacleCount;
}

int sdContextNumberOfObstacles (SDContext *context) {
	// Param check.
	if (context == NULL) {
		return 0;
	}
	return context->obstacleCount;
}

Obstacle *sdContextObstacleAtIndex (SDContext *context, int index) {
	// Param check.
	if ((context == NULL) || (index < 0) || (index >= context->obstacleCount)) {
		return NULL;
	}
	return &(context->obstacleArray[index]);
}

int sdContextRenderToBitmap (SDContext *context, BMContext *bitmap) {
	// Param check.
	if (context == NULL) {
    	return 0;
	}
	
	int width = bmContextWidth (bitmap);
	int height = bmContextHeight (bitmap);
	double scale = 1.0;
	if ((width != context->width) || (height != context->height)) {
		scale = MAX ((double) width / context->width, (double) height / context->height);
	}
	
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			double scaledX = (double) x / scale;
			double scaledY = (double) y / scale;
			double luminance = _sdContextGetLuminanceForPoint (context, scaledX, scaledY);
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
	return 1;
}

void sdContextFree (SDContext *context) {
	// NOP.
	if (context == NULL) {
		return;
	}
	
	// Free name.
	if (context->name) {
		free (context->name);
	}
	context->name = NULL;

	// Free lamps.
	if (context->lampArray) {
		free (context->lampArray);
	}
	context->lampArray = NULL;
	context->lampCount = 0;
	
	// Free obstacles.
	if (context->obstacleArray) {
		free (context->obstacleArray);
	}
	context->obstacleArray = NULL;
	context->obstacleCount = 0;
	
	free (context);
}
