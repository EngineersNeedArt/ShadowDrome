//
//  Lamp.c
//

#include <stdlib.h>
#include "Lamp.h"


Lamp *lampCreate (double x, double y) {
	Lamp *lamp = malloc (sizeof(Lamp));
	lamp->xLoc = x;
	lamp->yLoc = y;
	lamp->radius = 10.0;		// A 'unit' in VPX is about 0.5mm, so this is a 5mm radius for the lamp.
	lamp->intensity = 10.0;
	return lamp;
}
