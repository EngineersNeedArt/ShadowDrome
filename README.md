# ShadowDrome

### Description
An experimental ray-tracer to generate a shadow overlay for virtual pinball playfields.

### Current State
At this point it is a very user-unfriendly tool with hard-coded values to generate a ray-traced image of shadows for the pinball table "Slick Chick". The output appears below:

<p align="center">
<img src="https://github.com/EngineersNeedArt/ShadowDrome/blob/48955666e338895c3e1af8b04d975974db07b5a1/Images/SlickChickAndShadows.jpg">
  <br>
<i>Slick Chick table on left, ray-traced shadow map on right.</i>
</p>

### How it Works

A `ShadowContext` in the app is intended to hold information about each light on the pinball playfield and each "obstacle". A single call to `sdContextRenderToBitmap()` will kick off the ray-tracing and will fill the bitmap with an image (as above) representing the shadows cast by the lights, as blocked by the obstacles, to each individual pixel.

To initially populate the `ShadowContext` with light sources, you makes calls to `sdContextAddLamp()`. A `Lamp` is a simple object specifying an `x` and `y` location within the context (on the playfield) and a `radius` and `intensity`. Currently there is no affordance for the height the lamp is above the playfield (the code is strictly 2D-based for simplicity).

To populate the `ShadowContext` with obstacles that block the rays of light, you make calls to `sdContextAddObstacle()`. An `Obstacle` is merely an array of points (vertices) that specify a polygonal prism. Again, for simplicity, the code is running 2D ray-traces and so there is no notion of height for the obstacles. The vertices of the polygon are in clockwise order and are assumed to be non-convex polygons. The area represented by the polygon in the `ShadowContext` (on the playfield) is assumed to block all light from the light sources.

To determine the amount of light hitting each pixel of a bitmap (an RGB + alpha bitmap) a number of tests and calculations are performed.

First, the pixel's `x` and `y` location within the bitmap are tested as to whether it is enclosed within any `Obstacle` in the `ShadowContext`. As you can guess, if the pixel is within an `Obstacle` polygon it receives no light whatsoever. That pixel is set to black (by default) and 100% alpha (meaning 100% opaque).

If however the pixel is not enclosed, a line segment for each light source (`Lamp`) is calculated and the intersection with every vertex of every `Obstacle` polygon is tested. In other words, is there a direct line-of-sight between the pixel and a given `Lamp`? Or is there an `Obstacle` blocking the light?

<p align="center">
<img width="600" src="https://github.com/EngineersNeedArt/ShadowDrome/blob/e905c9ed3cd2adc68bee64f35212d8c1770c882e/Images/Diagram1.jpg">
  <br>
<i>Pixel luminosity being considered with lines to two lamps, Lamp 0 is blocked by an obstacle, Lamp 1 is not.</i>
</p>

As in the previous enclosed case, if there is an edge of an `Obstacle` polygon blocking the light, the luminosity contributed by that light is zero and it will remain black. However we are not necessarily done with the pixel because there are often multiple light sources and we need to calculate the contribution of light from all sources.

If on the other hand there is a direct, uninterrupted line to a light source, a luminosity value is calculated using the inverse-square law (the inverse of the distance the pixel is from the light source). But also as above, we must continue through all the other light sources in the `ShadowContext` to get the combined luminosity from *all* `Lamps` in order to determine the value for the pixel.

When we finaly have our composite luminosity value it is only applied to the alpha value of the pixel. Again the pixel is black by default but if suitably lit it may have an alpha value as low as zero (indicating the pixel is completely transparent and contributes no shadow to the pinball table).

### Penumbra

If I had treated the `Lamps` as point-sources, there would have been very hard edges on the shadows rendered. Because light bulbs are not point-sources (there is a filament that has some width, never mind the globe of the bulb) I had to add extra steps to calculate lines-of-sight not just for the `x` and `y` of each `Lamp` but also for points perpendicular to the path to the lamp some distance to one side of the line and the other. This is why the `Lamp` has a radius - it indicates how far out from center to make additional line-of-sight tests.

By adding all the results of all these extra line-of-sight tests to the luminosity for each pixel you can imagine now how the penumbra forms. For pixels clearly in full gaze of the lamp, they will be fully lit. And similarly, pixels fully obscured from all points of the lamp even when the lamp radius is allowed, are completely in shadow. However, we have now introduced the edge cases where some fraction of the lamp is visible from the vantage point of the pixel, but not all. These pixels get only a proportional amount of illumination from the lamp and will "feather" the edges of the shadows.
