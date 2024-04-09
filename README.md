# ShadowDrome

### Description
<i>An experimental ray-tracer to generate a shadow overlay for virtual pinball playfields.</i>

Visual Pinball (VPX) is getting to be a pretty sophisticated open-source, virtual pinball game with over 1000 user-created tables along with pinball backglass files and other support files. One thing table creators do to help a pinball table achieve another level of realism is to add the shadows that you might get with all the lights and obstacles on a pinball table. While the VPX software itself can handle a good deal of rendering a dynamic pinball table, ray-tracing shadows is something still out of its reach.

To that end table creators pre-render these shadows. If you have the time and know-how, you can model the table in Blender and can achieve perhaps shadows as good as is possible. If instead you have the skills with using paint tools like Photoshop or Affinity Photo you can achieve a more stylish representation of a pinball table's shadows and add to the realism that way.

This project was an experiment to see what a simple ray-tracer-like app could do to calculate those shadows without the complexity of Blender or requiring art skills. It does require the position of the lights and obstacles on the pinball table be specified and then it calculates the resulting illumination for each pixel on a bitmap (representing pixels on the playfield). It saves the resulting shadow map as a PNG file (luminosity is represented in the alpha channel of the bitmap).

### Current State

At this point it is a very user-unfriendly tool with hard-coded values to generate a ray-traced image of shadows for the pinball table "Slick Chick". The output appears below:

<p align="center">
<img src="https://github.com/EngineersNeedArt/ShadowDrome/blob/ff1d766c13492eaf3de062e49f511090166c9bb6/Images/SlickChickAndShadows.jpg">
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

When we finally have our composite luminosity value it is only applied to the alpha value of the pixel. Again the pixel is black by default but if suitably lit it may have an alpha value as low as zero (indicating the pixel is completely transparent and contributes no shadow to the pinball table).

### Penumbra

If I had treated the `Lamps` as point-sources, there would have been very hard edges on the shadows rendered. Because light bulbs are not point-sources (there is a filament that has some width, never mind the globe of the bulb) I had to add extra steps to calculate lines-of-sight not just for the `x` and `y` of each `Lamp` but also for points perpendicular to the path to the lamp some distance to one side of the line and the other. This is why the `Lamp` has a radius - it indicates how far out from center to make additional line-of-sight tests.

<p align="center">
<img width="450" src="https://github.com/EngineersNeedArt/ShadowDrome/blob/af38b5c9b3e6df7d3c9ac877045bb66987b3c3cd/Images/Diagram2.jpg">
  <br>
<i>Diagram showing the line-of-sight for 3 different points on a line perpendicular to the pixel-under-test. In this illustration, only 2/3 of the light reaches the pixel. In practice, depending on the lamp radius, it is closer to a dozen (closely spaced) points tested.</i>
</p>

By adding all the results of all these extra line-of-sight tests to the luminosity for each pixel you can imagine now how the penumbra forms. For pixels clearly in full gaze of the lamp, they will be fully lit. And similarly, pixels fully obscured from all points of the lamp even when the lamp radius is allowed, are completely in shadow. However, we have now introduced the edge cases where some fraction of the lamp is visible from the vantage point of the pixel, but not all. These pixels get only a proportional amount of illumination from the lamp and will "feather" the edges of the shadows.

### Creating Shadows

TBD

### Data In and Out

I added a simple JSON representation for the shadow context. This then allows you to save the state of a shadow context that you create as a text file and then later open the file and read it back in to restore the shadow context. While the `Obstacles` in the shadow context reduce to polygons (arrays of `x/y` coordinates) I try to preserve to a degree the means by which the obstacles were created in the UI. So that a cyclindrical `Obstacle` with some radius is not exported in JSON as the vertices but instead as the original `x/y` center of the cylinder and the radius. By doing so the UI of the app can continue to allow the user to simply change the value of the radii and have a new set of vertices generated.

The **Open Shadow** and **Save Shadow** buttons in the UI are for opening and saving these JSON files — they use a `.shadow` prefix.

The **Export Bitmap** button is the control that generates the high resolution PNG file that you can then use for virtual pinball.

_Warning: generating the PNG image can be slow as it works at the full resolution of your shadow context._

### Future State

Performance is extremely lacking in the code. Only the most obvious performance optimizations were implemented in the core: like the initial test to see if a pixel is enclosed by an obstacle, or returning when the first edge of a polygon is found to intersect a line-of-sight line segment.

For the calling application I did take advantage of MacOS's GCD (Grand Central Dispatch) so that all the useable cores on a device will be pressed into service to handle the ray-tracing. That was a huge win.

As hinted at earlier, adding a 3rd dimension to the ray-tracing would allow more complex but realistic shadow generation. As an example, many pinball tables have a round target whose shadow ought to be an elongated ellipse, not a frustum as the current implementation would generate.
