//
//  ShadowContextJSONLayer.c
//


#include <math.h>
#include <string.h>
#include <stdlib.h>
#include "cJSON.h"
#include "Lamp.h"
#include "Obstacle.h"
#include "ShadowContextJSONLayer.h"


#pragma mark - Private

double _sdContextDoubleTo3DecimalPlaces (double raw) {
	return round (raw * 1000) / 1000;
}

bool _sdContextAddLampsJSON (cJSON *lamps, SDContext *context) {
	bool success = false;
	Lamp *lampPtr = context->lampArray;
	for (int l = 0; l < context->lampCount; l++) {
		cJSON *oneLamp = cJSON_CreateObject ();
		
		if (cJSON_AddNumberToObject (oneLamp, "xLoc", lampPtr->xLoc) == NULL) {
			goto bail;
		}
		if (cJSON_AddNumberToObject (oneLamp, "yLoc", lampPtr->yLoc) == NULL) {
			goto bail;
		}
		if (cJSON_AddNumberToObject (oneLamp, "radius", lampPtr->radius) == NULL) {
			goto bail;
		}
		if (cJSON_AddNumberToObject (oneLamp, "intensity", lampPtr->intensity) == NULL) {
			goto bail;
		}
		
		// Add lamp to lamp array.
		cJSON_AddItemToArray (lamps, oneLamp);
		
		lampPtr++;
	}
	
	success = true;
	
bail:
	
	return success;
}

bool _sdContextAddObstaclesJSON (cJSON *obstacles, SDContext *context) {
	bool success = false;
	double *lowPrecisionVertices = NULL;
	
	Obstacle *obstaclePtr = context->obstacleArray;
	for (int o = 0; o < context->obstacleCount; o++) {
		cJSON *oneObstacle = cJSON_CreateObject ();
		
		switch (obstaclePtr->kind) {
			case ObstacleKindPolygonalPrism:
			if (cJSON_AddStringToObject(oneObstacle, "kind", "polygon") == NULL) {
				goto bail;
			}
			break;
			
			case ObstacleKindCylinder:
			if (cJSON_AddStringToObject(oneObstacle, "kind", "cylinder") == NULL) {
				goto bail;
			}
			break;
			
			case ObstacleKindRectangularPrism:
			if (cJSON_AddStringToObject(oneObstacle, "kind", "rectangle") == NULL) {
				goto bail;
			}
			break;
			
			default:
			goto bail;
			break;
		}
		
		switch (obstaclePtr->role) {
			case ObstacleRoleBlocksLight:
			if (cJSON_AddStringToObject(oneObstacle, "role", "blocks") == NULL) {
				goto bail;
			}
			break;
			
			case ObstacleRoleVoidsShadows:
			if (cJSON_AddStringToObject(oneObstacle, "role", "voids") == NULL) {
				goto bail;
			}
			break;
			
			default:
			goto bail;
			break;
		}
		
		if (obstaclePtr->xCenter != 0.0) {
			if (cJSON_AddNumberToObject (oneObstacle, "xCenter", _sdContextDoubleTo3DecimalPlaces (obstaclePtr->xCenter)) == NULL) {
				goto bail;
			}
		}
		
		if (obstaclePtr->yCenter != 0.0) {
			if (cJSON_AddNumberToObject (oneObstacle, "yCenter", _sdContextDoubleTo3DecimalPlaces (obstaclePtr->yCenter)) == NULL) {
				goto bail;
			}
		}
		
		if (obstaclePtr->width != 0.0) {
			if (cJSON_AddNumberToObject (oneObstacle, "width", obstaclePtr->width) == NULL) {
				goto bail;
			}
		}
		if (obstaclePtr->height != 0.0) {
			if (cJSON_AddNumberToObject (oneObstacle, "height", obstaclePtr->height) == NULL) {
				goto bail;
			}
		}
		
		if (obstaclePtr->radius != 0.0) {
			if (cJSON_AddNumberToObject (oneObstacle, "radius", obstaclePtr->radius) == NULL) {
				goto bail;
			}
		}
		if (obstaclePtr->rotationDegrees != 0.0) {
			if (cJSON_AddNumberToObject (oneObstacle, "rotationDegrees", obstaclePtr->rotationDegrees) == NULL) {
				goto bail;
			}
		}
		
		// Vertices.
		if (obstaclePtr->kind == ObstacleKindPolygonalPrism) {
			cJSON_AddNumberToObject (oneObstacle, "numVertices", obstaclePtr->numVertices);
			double *lowPrecisionVertices = malloc (sizeof(double) * obstaclePtr->numVertices * 2);
			double *srcVertexPtr = obstaclePtr->vertexArray;
			double *destVertexPtr = lowPrecisionVertices;
			for (int v = 0; v < (obstaclePtr->numVertices * 2); v++) {
				*destVertexPtr = _sdContextDoubleTo3DecimalPlaces (*srcVertexPtr);
				if ((v + 1) < (obstaclePtr->numVertices * 2)) {
					srcVertexPtr++;
					destVertexPtr++;
				}
			}
			cJSON *vertices = cJSON_CreateDoubleArray (lowPrecisionVertices, obstaclePtr->numVertices * 2);
			if (!cJSON_AddItemToObject(oneObstacle, "vertices", vertices)) {
				goto bail;
			}
		}
		// Add obstacle to obstacle array.
		cJSON_AddItemToArray (obstacles, oneObstacle);
		
		obstaclePtr++;
	}
	
	success = true;
	
bail:
	
	if (lowPrecisionVertices) {
		free (lowPrecisionVertices);
	}
	
	return success;
}

#pragma mark - Public

char *sdContextJSONRepresentation (SDContext *context) {
	char *jsonString = NULL;
	
	// Create (root) container for the context.
	cJSON *jsonContext = cJSON_CreateObject ();
	cJSON *lamps = NULL;
	cJSON *obstacles = NULL;
	
	// Add top-level fields.
	if (cJSON_AddNumberToObject (jsonContext, "version", 0) == NULL) {
		goto bail;
	}
	if (cJSON_AddStringToObject (jsonContext, "title", context->name) == NULL) {
		goto bail;
	}
	
	if (cJSON_AddNumberToObject (jsonContext, "width", context->width) == NULL) {
		goto bail;
	}
	if (cJSON_AddNumberToObject (jsonContext, "height", context->height) == NULL) {
		goto bail;
	}
	
	// Add lamp array.
	lamps = cJSON_AddArrayToObject (jsonContext, "lamps");
	if (lamps == NULL) {
		goto bail;
	}
	if (!_sdContextAddLampsJSON (lamps, context)) {
		goto bail;
	}
	
	// Add obstacle array.
	obstacles = cJSON_AddArrayToObject (jsonContext, "obstacles");
	if (obstacles == NULL) {
		goto bail;
	}
	if (!_sdContextAddObstaclesJSON (obstacles, context)) {
		goto bail;
	}
	
	// Get JSON.
	jsonString = cJSON_Print (jsonContext);
	
bail:
	
	cJSON_Delete (jsonContext);
	
	return jsonString;
}
