//
//  Obstacle.h
//

#ifndef Obstacle_h
#define Obstacle_h

#include <stdio.h>


typedef struct {
	double xLoc;
	double yLoc;
	int numVertices;
	double *vertexArray;	// ordered: [x0, y0, x1, y1 ... xn, yn], count = numVertices * 2
	double minX;
	double minY;
	double maxX;
	double maxY;
} Obstacle;

// Pass four verticies in clockwise order.
Obstacle *obstacleCreateQuadPrism (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3);

// Pass top left corner (x0, y0) and bottom right corner (x1, y1).
Obstacle *obstacleCreateRectangluarPrism (double x0, double y0, double x1, double y1);

Obstacle *obstacleCreateCylinder (double x, double y, double radius);


#endif /* Obstacle_h */
