//
//  Obstacle.h
//

#ifndef Obstacle_h
#define Obstacle_h

#include <stdio.h>
#include <stdbool.h>


typedef enum {
	ObstacleKindPolygonalPrism,
	ObstacleKindCylinder,
	ObstacleKindRectangularPrism,
	ObstacleKindCount
} ObstacleKind;

typedef enum {
	ObstacleRoleBlocksLight,
	ObstacleRoleVoidsShadows,
	ObstacleRoleCount
} ObstacleRole;


typedef struct {
	ObstacleKind kind;
	ObstacleRole role;
	double xCenter;
	double yCenter;
	double radius;				// Optional, only applies to ObstacleKindCylinder.
	double rotationDegrees;		// Optional, only applies to ObstacleKindRectangularPrism.
	int numVertices;			// Number of (x, y) pairs (e.g., for a rectangle, numVertices=4).
	double *vertexArray;		// ordered: [x0, y0, x1, y1 ... xn, yn], count = numVertices * 2 (e.g., for a rectangle, vertexArray count=8).
	double minX;				// Smallest x value in vertexArray (used for bounds testing vertices).
	double minY;				// Smallest y value in vertexArray (used for bounds testing vertices).
	double maxX;				// Largest x value in vertexArray (used for bounds testing vertices).
	double maxY;				// Largest y value in vertexArray (used for bounds testing vertices).
} Obstacle;

/// Initializer/allocater. Number of doubles passed in vertexArray should be twice vertexCount. Caller can free vertexArray after, values are copied.
Obstacle *obstacleCreate (double *vertexArray, int vertexCount);

/// Convenience initializer/allocater. Pass four verticies in clockwise order.
Obstacle *obstacleCreateQuadPrism (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3);

/// Convenience initializer/allocater. Pass top left corner (x0, y0) and bottom right corner (x1, y1).
Obstacle *obstacleCreateRectangluarPrism (double x0, double y0, double x1, double y1);

/// Convenience initializer/allocater. Pass center (x, y), width, height and rotation (in degrees) of the rectangular prism.
Obstacle *obstacleCreateRotatedRectangularPrism (double x, double y, double width, double height, double rotationDegrees);

/// Convenience initializer/allocater. Pass the center (x, y), and radius of the cylinder.
Obstacle *obstacleCreateCylinder (double x, double y, double radius);

/// By default an obstacle blocks light, but specifying shouldVoid will cause the object to instead disallow shadows within its polygon interior.
void obstacleShouldVoidShadows (Obstacle *obstacle, bool shouldVoid);

/// Frees memory allocated by obstacle.
void obstacleFree (Obstacle *obstacle);

#endif /* Obstacle_h */
