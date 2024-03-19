//
//  Lamp.h
//

#ifndef Lamp_h
#define Lamp_h

#include <stdio.h>


typedef struct {
	double xLoc;
	double yLoc;
	double radius;
	double intensity;
} Lamp;

/// Creates a lamp at point x, y.
Lamp *lampCreate (double x, double y);

/// Free storage for lamp.
void lampFree (Lamp *lamp);

#endif /* Lamp_h */
