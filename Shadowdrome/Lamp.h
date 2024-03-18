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

Lamp *lampCreate (double x, double y);


#endif /* Lamp_h */
