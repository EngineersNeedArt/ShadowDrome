//
//  BitmapContext.c
//

#include <stdlib.h>
#include "BitmapContext.h"

BMContext *bmContextCreate (int width, int height) {
	BMContext *context = malloc (sizeof(BMContext));
	context->width = width;
	context->height = height;
	context->buffer = malloc (sizeof(unsigned char) * width * height * 4);
	
	// Clear context to black.
	bmContextFillBuffer (context, 0, 0, 0, 255);
	
	return context;
}

int bmContextWidth (BMContext *context) {
	return context->width;
}

int bmContextHeight (BMContext *context) {
	return context->height;
}

unsigned char *bmContextBufferPtr (BMContext *context) {
	if (context) {
		return context->buffer;
	} else {
		return NULL;
	}
}

size_t bmContextBufferSize (BMContext *context) {
	if (context) {
		return context->width * context->height * 4;
	} else {
		return 0;
	}
}

unsigned char *bmContextPixelPtr (BMContext *context, int x, int y) {
	unsigned char *pixelPtr = NULL;
	
	if (context) {
		pixelPtr = context->buffer;
		pixelPtr += ((y * context->width) + x) * 4;
	}
	
	return pixelPtr;
}

void bmContextFillBuffer (BMContext *context, unsigned char red, unsigned char green,
		unsigned char blue, unsigned char alpha) {
	int pixelCount = context->width * context->height;
	int index = 0;
	unsigned char *component = context->buffer;
	while (index < pixelCount) {
		*component = red;
		component++;
		*component = green;
		component++;
		*component = blue;
		component++;
		*component = alpha;
		component++;
		index++;
	}
}

void bmContextGetPixel (BMContext *context, int x, int y, unsigned char *red, unsigned char *green,
		unsigned char *blue, unsigned char *alpha) {
	unsigned char *pixelPtr = bmContextPixelPtr (context, x, y);
	if (pixelPtr) {
		if (red) {
			*red = *pixelPtr;
		}
		pixelPtr++;
		if (green) {
			*green = *pixelPtr;
		}
		pixelPtr++;
		if (blue) {
			*blue = *pixelPtr;
		}
		pixelPtr++;
		if (alpha) {
			*alpha = *pixelPtr;
		}
	}
}

void bmContextSetPixel (BMContext *context, int x, int y, unsigned char red, unsigned char green,
		unsigned char blue, unsigned char alpha) {
	unsigned char *pixelPtr = bmContextPixelPtr (context, x, y);
	if (pixelPtr) {
		*pixelPtr = red;
		pixelPtr++;
		*pixelPtr = green;
		pixelPtr++;
		*pixelPtr = blue;
		pixelPtr++;
		*pixelPtr = alpha;
		pixelPtr++;
	}
}

void bmContextFree (BMContext *context) {
	// NOP.
	if (context == NULL) {
		return;
	}
	
	// Free buffer.
	if (context->buffer) {
		free (context->buffer);
	}
	context->buffer = NULL;
	
	free (context);
}
