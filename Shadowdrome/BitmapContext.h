//
//  BitmapContext.h
//

#ifndef BitmapContext_h
#define BitmapContext_h

#include <stdio.h>

typedef struct {
	int width;
	int height;
	unsigned char *buffer;
} BMContext;

BMContext *bmContextCreate (int width, int height);

int bmContextWidth (BMContext *context);

int bmContextHeight (BMContext *context);

unsigned char *bmContextBufferPtr (BMContext *context);

size_t bmContextBufferSize (BMContext *context);

void bmContextFillBuffer (BMContext *context, unsigned char red, unsigned char green,
		unsigned char blue, unsigned char alpha);

void bmContextGetPixel (BMContext *context, int x, int y, unsigned char *red, unsigned char *green,
		unsigned char *blue, unsigned char *alpha);

void bmContextSetPixel (BMContext *context, int x, int y, unsigned char red, unsigned char green,
		unsigned char blue, unsigned char alpha);

#endif /* BitmapContext_h */
