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
		
		if (obstaclePtr->opacity != 1.0) {
			if (cJSON_AddNumberToObject (oneObstacle, "opacity", obstaclePtr->opacity) == NULL) {
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

SDContext *sdContextCreateFromJSONRepresentation (const char *json) {
	SDContext *context = NULL;
	cJSON *rootObject = cJSON_Parse (json);
	if (rootObject == NULL) {
		goto bail;
	}
	
	// Get basic information for shadow context.
	int version = round (cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (rootObject, "version")));
	char *title = cJSON_GetStringValue (cJSON_GetObjectItemCaseSensitive (rootObject, "title"));
	int width = round (cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (rootObject, "width")));
	int height = round (cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (rootObject, "height")));
	
	// Sanity check.
	if ((version != 0) || (title == NULL) || (width <= 0) || (height <= 0)) {
		goto bail;
	}
	
	// Create shadow context.
	context = sdContextCreate( title, width, height);
	
	// Parse lamps.
	cJSON *lampsJSON = cJSON_GetObjectItemCaseSensitive (rootObject, "lamps");
	if (cJSON_IsArray (lampsJSON)) {
		int numLamps = cJSON_GetArraySize (lampsJSON);
		for (int l = 0; l < numLamps; l++) {
			cJSON* oneLampJSON = cJSON_GetArrayItem (lampsJSON, l);
			double x = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneLampJSON, "xLoc"));
			double y = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneLampJSON, "yLoc"));
			Lamp *lamp = lampCreate (x, y);
			lampSetRadius (lamp, cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneLampJSON, "radius")));
			lampSetIntensity (lamp, cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneLampJSON, "intensity")));
			sdContextAddLamp (context, lamp);
		}
	}
	
	// Parse obstacles.
	cJSON *obstaclesJSON = cJSON_GetObjectItemCaseSensitive (rootObject, "obstacles");
	if (cJSON_IsArray (obstaclesJSON)) {
		int numObstacles = cJSON_GetArraySize (obstaclesJSON);
		for (int o = 0; o < numObstacles; o++) {
			cJSON* oneObstacleJSON = cJSON_GetArrayItem (obstaclesJSON, o);
			char *kind = cJSON_GetStringValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "kind"));
			Obstacle *obstacle = NULL;
			if (strcmp (kind, "cylinder") == 0) {
				double x = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "xCenter"));
				double y = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "yCenter"));
				double radius = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "radius"));
				obstacle = obstacleCreateCylinder (x, y, radius);
			} else if (strcmp (kind, "rectangle") == 0) {
				double rotationDegrees = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "rotationDegrees"));
				double x = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "xCenter"));
				double y = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "yCenter"));
				double width = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "width"));
				double height = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "height"));
				if (isnan (rotationDegrees)) {
					double x0 = x - (width / 2.0);
					double y0 = y - (height / 2.0);
					obstacle = obstacleCreateRectangluarPrism (x0, y0, x0 + width, y0 + height);
				} else {
					obstacle = obstacleCreateRotatedRectangularPrism (x, y, width, height, rotationDegrees);
				}
			} else if (strcmp (kind, "polygon") == 0) {
				int numVertices = round (cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "numVertices")));
				cJSON *vertexJSON = cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "vertices");
				if (cJSON_IsArray (vertexJSON)) {
					int numValues = cJSON_GetArraySize (vertexJSON);
					double *buffer = malloc(sizeof(double) * numValues);
					for (int i = 0; i < numValues; i++) {
						double value = cJSON_GetNumberValue (cJSON_GetArrayItem (vertexJSON, i));
						buffer[i] = value;
					}
					obstacle = obstacleCreate (buffer, numVertices);
					free (buffer);
				}
			}
			
			if (obstacle) {
				double opacity = cJSON_GetNumberValue (cJSON_GetObjectItemCaseSensitive (oneObstacleJSON, "opacity"));
				if (isnan (opacity)) {
					obstacleSetOpacity (obstacle, opacity);
				}
				sdContextAddObstacle (context, obstacle);
			}
		}
	}
	
bail:
	
	return context;
}
