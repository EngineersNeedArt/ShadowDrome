//
//  ShadowContextJSONLayer.h
//

#ifndef ShadowContextJSONLayer_h
#define ShadowContextJSONLayer_h

#include <stdio.h>
#include "ShadowContext.h"


char *sdContextJSONRepresentation (SDContext *context);

SDContext *sdContextCreateFromJSONRepresentation (const char *json);


#endif /* ShadowContextJSONLayer_h */
