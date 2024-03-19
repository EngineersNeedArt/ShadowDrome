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

/// Create an 8-bit RGBA bitmap context.
BMContext *bmContextCreate (int width, int height);

/// Returns the bitmap width.
int bmContextWidth (BMContext *context);

/// Returns the bitmap height.
int bmContextHeight (BMContext *context);

/// Returns the pointer to the bitmap buffer. The buffer is 4 x width x height bytes in size.
unsigned char *bmContextBufferPtr (BMContext *context);

/// Returns the bitmap buffer size. Size is 4 x width x height bytes.
size_t bmContextBufferSize (BMContext *context);

/// Fills entire bitmap buffer with RGBA value specified.
void bmContextFillBuffer (BMContext *context, unsigned char red, unsigned char green,
		unsigned char blue, unsigned char alpha);

/// Get the RGBA value for the pixel at x, y.
void bmContextGetPixel (BMContext *context, int x, int y, unsigned char *red, unsigned char *green,
		unsigned char *blue, unsigned char *alpha);

/// Set the RGBA value for the pixel at x, y.
void bmContextSetPixel (BMContext *context, int x, int y, unsigned char red, unsigned char green,
		unsigned char blue, unsigned char alpha);

/// Free bitmap context.
void bmContextFree (BMContext *context);

#endif /* BitmapContext_h */
