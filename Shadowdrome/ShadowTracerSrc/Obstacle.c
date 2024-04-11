//
//  Obstacle.c
//

#include <math.h>
#include <stdlib.h>
#include "Obstacle.h"

#pragma mark - Private

Obstacle *_obstacleCreateBase (void) {
	Obstacle *obstacle = malloc (sizeof (Obstacle));
	obstacle->kind = ObstacleKindPolygonalPrism;
	obstacle->xCenter = 0.0;
	obstacle->yCenter = 0.0;
	obstacle->width = 0.0;
	obstacle->height = 0.0;
	obstacle->radius = 0.0;
	obstacle->rotationDegrees = 0.0;
	obstacle->opacity = 1.0;
	obstacle->minX = 0.0;
	obstacle->minY = 0.0;
	obstacle->maxX = 0.0;
	obstacle->maxY = 0.0;
	
	return obstacle;
}

void _obstacleAssignMinMaxBounds (Obstacle *obstacle) {
	double *vertexPtr = obstacle->vertexArray;
	
	// Walk all vertices. Keep running total for x and y for center finding (averaging).
	// Keep track of smallesrt x and y and largest x and y for bounds testing later.
	for (int i = 0; i < obstacle->numVertices; i++) {
		if (*vertexPtr < obstacle->minX) {
			obstacle->minX = *vertexPtr;
		}
		if (*vertexPtr > obstacle->maxX) {
			obstacle->maxX = *vertexPtr;
		}
		vertexPtr++;
		if (*vertexPtr < obstacle->minY) {
			obstacle->minY = *vertexPtr;
		}
		if (*vertexPtr > obstacle->maxY) {
			obstacle->maxY = *vertexPtr;
		}
		if ((i + 1) < obstacle->numVertices) {
			vertexPtr++;
		}
	}
}

void _obstacleOffsetVertices (Obstacle *obstacle, double x, double y) {
	double *vertexPtr = obstacle->vertexArray;
	for (int i = 0; i < obstacle->numVertices; i++) {
		*vertexPtr += x;
		vertexPtr++;
		*vertexPtr += y;
		if ((i + 1) < obstacle->numVertices) {
			vertexPtr++;
		}
	}
}

void _obstacleAssignCylindricalVertices (Obstacle *obstacle) {
	// Free existing points (if any).
	if (obstacle->vertexArray) {
		free (obstacle->vertexArray);
	}
	
	obstacle->numVertices = round (obstacle->radius / 2);
	if (obstacle->numVertices < 8) {
		obstacle->numVertices = 8;
	}
	obstacle->vertexArray = malloc (sizeof (double) * obstacle->numVertices * 2);
	
	double *vertexPtr = obstacle->vertexArray;
	for (int i = 0; i < obstacle->numVertices; i++) {
		double xD = sin (i * M_PI * 2 / obstacle->numVertices) * obstacle->radius;
		*vertexPtr = obstacle->xCenter + xD;
		vertexPtr++;
		double yD = cos (i * M_PI * 2 / obstacle->numVertices) * obstacle->radius;
		*vertexPtr = obstacle->yCenter + yD;
		if ((i + 1) < obstacle->numVertices) {
			vertexPtr++;
		}
	}
}

void _obstacleAssignRotatedRectangularPrismVertices  (Obstacle *obstacle) {
	double *vertexPtr = obstacle->vertexArray;
	double angle = obstacle->rotationDegrees / 180.0 * M_PI;
	
	double xV = ((obstacle->width / 2.0) * cos (angle)) - ((-obstacle->height / 2.0) * sin (angle));
	double yV = ((obstacle->width / 2.0) * sin (angle)) + ((-obstacle->height / 2.0) * cos (angle));
	*vertexPtr = obstacle->xCenter + xV;
	vertexPtr++;
	*vertexPtr = obstacle->yCenter + yV;
	vertexPtr++;
	
	xV = ((obstacle->width / 2.0) * cos (angle)) - ((obstacle->height / 2.0) * sin (angle));
	yV = ((obstacle->width / 2.0) * sin (angle)) + ((obstacle->height / 2.0) * cos (angle));
	*vertexPtr = obstacle->xCenter + xV;
	vertexPtr++;
	*vertexPtr = obstacle->yCenter + yV;
	vertexPtr++;
	
	xV = ((-obstacle->width / 2.0) * cos (angle)) - ((obstacle->height / 2.0) * sin (angle));
	yV = ((-obstacle->width / 2.0) * sin (angle)) + ((obstacle->height / 2.0) * cos (angle));
	*vertexPtr = obstacle->xCenter + xV;
	vertexPtr++;
	*vertexPtr = obstacle->yCenter + yV;
	vertexPtr++;
	
	xV = ((-obstacle->width / 2.0) * cos (angle)) - ((-obstacle->height / 2.0) * sin (angle));
	yV = ((-obstacle->width / 2.0) * sin (angle)) + ((-obstacle->height / 2.0) * cos (angle));
	*vertexPtr = obstacle->xCenter + xV;
	vertexPtr++;
	*vertexPtr = obstacle->yCenter + yV;
}

#pragma mark - Public

Obstacle *obstacleCreate (double *vertexArray, int vertexCount) {
	Obstacle *obstacle = _obstacleCreateBase ();
	obstacle->kind = ObstacleKindPolygonalPrism;
	
	// Allocate storage for vertices.
	obstacle->numVertices = vertexCount;
	obstacle->vertexArray = malloc (sizeof (double) * obstacle->numVertices * 2);
	
	// Copy over vertices. Keep running total of x and y to find center later.
	double *vertexPtr = obstacle->vertexArray;
	double *vertexSourcePtr = vertexArray;
	for (int i = 0; i < obstacle->numVertices; i++) {
		// Copy x.
		*vertexPtr = *vertexSourcePtr;
		vertexPtr++;
		vertexSourcePtr++;
		
		// Copy y.
		*vertexPtr = *vertexSourcePtr;
		if ((i + 1) < obstacle->numVertices) {
			vertexPtr++;
			vertexSourcePtr++;
		}
	}
	
	// Find min/max for x and y.
	_obstacleAssignMinMaxBounds (obstacle);
	
	return obstacle;
}

Obstacle *obstacleCreateQuadPrism (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3) {
	Obstacle *obstacle = _obstacleCreateBase ();
	obstacle->kind = ObstacleKindPolygonalPrism;
	obstacle->numVertices = 4;
	obstacle->vertexArray = malloc (sizeof (double) * obstacle->numVertices * 2);
	
	double *vertexPtr = obstacle->vertexArray;
	*vertexPtr = x0;
	vertexPtr++;
	*vertexPtr = y0;
	vertexPtr++;
	*vertexPtr = x1;
	vertexPtr++;
	*vertexPtr = y1;
	vertexPtr++;
	*vertexPtr = x2;
	vertexPtr++;
	*vertexPtr = y2;
	vertexPtr++;
	*vertexPtr = x3;
	vertexPtr++;
	*vertexPtr = y3;
	
	// Find min/max for x and y.
	_obstacleAssignMinMaxBounds (obstacle);
	
	// Compute center x and y.
	obstacle->xCenter = (obstacle->minX + obstacle->maxX) / 2.0;
	obstacle->yCenter = (obstacle->minY + obstacle->maxY) / 2.0;
	
	return obstacle;
}

Obstacle *obstacleCreateRectangluarPrism (double x0, double y0, double x1, double y1) {
	Obstacle *obstacle = _obstacleCreateBase ();
	obstacle->kind = ObstacleKindRectangularPrism;
	obstacle->xCenter = (x0 + x1) / 2.0;
	obstacle->yCenter = (y0 + y1) / 2.0;
	obstacle->width = x1 - x0;
	obstacle->height = y1 - y0;
	obstacle->numVertices = 4;
	obstacle->vertexArray = malloc (sizeof (double) * obstacle->numVertices * 2);
	
	double *vertexPtr = obstacle->vertexArray;
	*vertexPtr = x0;
	vertexPtr++;
	*vertexPtr = y0;
	vertexPtr++;
	
	*vertexPtr = x1;
	vertexPtr++;
	*vertexPtr = y0;
	vertexPtr++;
	
	*vertexPtr = x1;
	vertexPtr++;
	*vertexPtr = y1;
	vertexPtr++;
	
	*vertexPtr = x0;
	vertexPtr++;
	*vertexPtr = y1;
	vertexPtr++;
	
	// Find min/max for x and y.
	_obstacleAssignMinMaxBounds (obstacle);
	
	return obstacle;
}

Obstacle *obstacleCreateRotatedRectangularPrism (double x, double y, double width, double height, double rotationDegrees) {
	Obstacle *obstacle = _obstacleCreateBase ();
	obstacle->kind = ObstacleKindRectangularPrism;
	obstacle->xCenter = x;
	obstacle->yCenter = y;
	obstacle->width = width;
	obstacle->height = height;
	obstacle->rotationDegrees = rotationDegrees;
	obstacle->numVertices = 4;
	obstacle->vertexArray = malloc (sizeof (double) * obstacle->numVertices * 2);
	
	// Assign vertices.
	_obstacleAssignRotatedRectangularPrismVertices (obstacle);
	
	// Find min/max for x and y.
	_obstacleAssignMinMaxBounds (obstacle);
	
	return obstacle;
}

Obstacle *obstacleCreateCylinder (double x, double y, double radius) {
	Obstacle *obstacle = _obstacleCreateBase ();
	obstacle->kind = ObstacleKindCylinder;
	obstacle->xCenter = x;
	obstacle->yCenter = y;
	obstacle->radius = radius;
	
	// Assign vertices.
	_obstacleAssignCylindricalVertices (obstacle);
	
	// Finds min/max for x and y.
	_obstacleAssignMinMaxBounds (obstacle);
	
	return obstacle;
}

Obstacle *obstacleSetXY (Obstacle *obstacle, double x, double y) {
	// Param check.
	if (obstacle == NULL) {
		return NULL;
	}
	
	// Offset vertices.
	double deltaX = x - obstacle->xCenter;
	double deltaY = y - obstacle->yCenter;
	_obstacleOffsetVertices (obstacle, deltaX, deltaY);
	
	// Assign.
	obstacle->xCenter = x;
	obstacle->yCenter = y;
	
	// Finds min/max for x and y.
	_obstacleAssignMinMaxBounds (obstacle);
	
	return obstacle;
}

Obstacle *obstacleSetRadius (Obstacle *obstacle, double radius) {
	// Param check.
	if (obstacle == NULL) {
		return NULL;
	}
	
	if (obstacle->kind == ObstacleKindCylinder) {
		// Assign.
		obstacle->radius = radius;
		
		// Compute new vertices.
		_obstacleAssignCylindricalVertices (obstacle);
		
		// Find new min/max for x and y.
		_obstacleAssignMinMaxBounds (obstacle);
	}
	
	return obstacle;
}

Obstacle *obstacleSetWidth (Obstacle *obstacle, double width) {
	// Param check.
	if (obstacle == NULL) {
		return NULL;
	}
	
	if (obstacle->kind == ObstacleKindRectangularPrism) {
		// Assign.
		obstacle->width = width;
		
		// Compute new vertices.
		_obstacleAssignRotatedRectangularPrismVertices (obstacle);
		
		// Find new min/max for x and y.
		_obstacleAssignMinMaxBounds (obstacle);
	}
	
	return obstacle;
}

Obstacle *obstacleSetHeight (Obstacle *obstacle, double height) {
	// Param check.
	if (obstacle == NULL) {
		return NULL;
	}
	
	if (obstacle->kind == ObstacleKindRectangularPrism) {
		// Assign.
		obstacle->height = height;
		
		// Compute new vertices.
		_obstacleAssignRotatedRectangularPrismVertices (obstacle);
		
		// Find new min/max for x and y.
		_obstacleAssignMinMaxBounds (obstacle);
	}
	
	return obstacle;
}

Obstacle *obstacleSetRotationDegrees (Obstacle *obstacle, double rotation) {
	// Param check.
	if (obstacle == NULL) {
		return NULL;
	}
	
	if (obstacle->kind == ObstacleKindRectangularPrism) {
		// Assign.
		obstacle->rotationDegrees = rotation;
		
		// Compute new vertices.
		_obstacleAssignRotatedRectangularPrismVertices (obstacle);
		
		// Find new min/max for x and y.
		_obstacleAssignMinMaxBounds (obstacle);
	}
	
	return obstacle;
}

Obstacle *obstacleSetOpacity (Obstacle *obstacle, double opacity) {
	// Param check.
	if (obstacle == NULL) {
		return NULL;
	}
	
	obstacle->opacity = opacity;
	return obstacle;
}

void obstacleFree (Obstacle *obstacle) {
	// NOP.
	if (obstacle == NULL) {
		return;
	}
	
	// Free polygon points.
	if (obstacle->vertexArray) {
		free (obstacle->vertexArray);
	}
	obstacle->vertexArray = NULL;
	obstacle->numVertices = 0;
	
	free (obstacle);
}
