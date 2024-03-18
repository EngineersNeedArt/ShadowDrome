//
//  Obstacle.c
//

#include <math.h>
#include <stdlib.h>
#include "Obstacle.h"

Obstacle *obstacleCreateQuadPrism (double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3) {
	Obstacle *obstacle = malloc (sizeof(Obstacle));
	obstacle->xLoc = (x0 + x1 + x2 + x3) / 4.0;
	obstacle->yLoc = (y0 + y1 + y2 + y3) / 4.0;
	
	obstacle->minX = x0;
	obstacle->minY = y0;
	obstacle->maxX = x0;
	obstacle->maxY = y0;
	
	obstacle->numVertices = 4;
	obstacle->vertexArray = malloc (sizeof(double) * obstacle->numVertices * 2);
	
	double *vertexPtr = obstacle->vertexArray;
	*vertexPtr = x0;
	if (x0 < obstacle->minX) {
		obstacle->minX = x0;
	}
	if (x0 > obstacle->maxX) {
		obstacle->maxX = x0;
	}
	vertexPtr++;
	*vertexPtr = y0;
	if (y0 < obstacle->minY) {
		obstacle->minY = y0;
	}
	if (y0 > obstacle->maxY) {
		obstacle->maxY = y0;
	}
	vertexPtr++;
	
	*vertexPtr = x1;
	if (x1 < obstacle->minX) {
		obstacle->minX = x1;
	}
	if (x1 > obstacle->maxX) {
		obstacle->maxX = x1;
	}
	vertexPtr++;
	*vertexPtr = y1;
	if (y1 < obstacle->minY) {
		obstacle->minY = y1;
	}
	if (y1 > obstacle->maxY) {
		obstacle->maxY = y1;
	}
	vertexPtr++;
	
	*vertexPtr = x2;
	if (x2 < obstacle->minX) {
		obstacle->minX = x2;
	}
	if (x2 > obstacle->maxX) {
		obstacle->maxX = x2;
	}
	vertexPtr++;
	*vertexPtr = y2;
	if (y2 < obstacle->minY) {
		obstacle->minY = y2;
	}
	if (y2 > obstacle->maxY) {
		obstacle->maxY = y2;
	}
	vertexPtr++;
	
	*vertexPtr = x3;
	if (x3 < obstacle->minX) {
		obstacle->minX = x3;
	}
	if (x3 > obstacle->maxX) {
		obstacle->maxX = x3;
	}
	vertexPtr++;
	*vertexPtr = y3;
	if (y3 < obstacle->minY) {
		obstacle->minY = y3;
	}
	if (y3 > obstacle->maxY) {
		obstacle->maxY = y3;
	}
	vertexPtr++;
	
	return obstacle;
}

Obstacle *obstacleCreateRectangluarPrism (double x0, double y0, double x1, double y1) {
	Obstacle *obstacle = malloc (sizeof(Obstacle));
	obstacle->xLoc = x0 + x1 / 2.0;
	obstacle->yLoc = y0 + y1 / 2.0;
	
	obstacle->minX = x0;
	obstacle->minY = y0;
	obstacle->maxX = x1;
	obstacle->maxY = y1;
	
	obstacle->numVertices = 4;
	obstacle->vertexArray = malloc (sizeof(double) * obstacle->numVertices * 2);
	
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
	
	return obstacle;
}

Obstacle *obstacleCreateCylinder (double x, double y, double radius) {
	Obstacle *obstacle = malloc (sizeof(Obstacle));
	obstacle->xLoc = x;
	obstacle->yLoc = y;
	
	obstacle->minX = x;
	obstacle->minY = y;
	obstacle->maxX = x;
	obstacle->maxY = y;
	
	obstacle->numVertices = 8;
	obstacle->vertexArray = malloc (sizeof(double) * obstacle->numVertices * 2);
	double *vertexPtr = obstacle->vertexArray;
	for (int i = 0; i < 8; i++) {
		double xD = sin (i * M_PI / 4) * radius;
		double yD = cos (i * M_PI / 4) * radius;
		*vertexPtr = x + xD;
		if (*vertexPtr < obstacle->minX) {
			obstacle->minX = *vertexPtr;
		}
		if (*vertexPtr > obstacle->maxX) {
			obstacle->maxX = *vertexPtr;
		}
		vertexPtr++;
		*vertexPtr = y + yD;
		if (*vertexPtr < obstacle->minY) {
			obstacle->minY = *vertexPtr;
		}
		if (*vertexPtr > obstacle->maxY) {
			obstacle->maxY = *vertexPtr;
		}
		vertexPtr++;
	}
	
	return obstacle;
}

