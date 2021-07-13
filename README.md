# Gaming in Non-Euclidean Geometry for Unity

This small project demonstrates how to transform [Unity](https://unity.com)'s rendering pipeline to render scenes as if we were in a 3D curved space – specifically 3D Elliptic geometry or 3D Hyperbolic geometry - with as few modifications as possible.

Check the [preliminary paper](https://diglib.eg.org/handle/10.2312/egs20211010) for a technical description and the corresponding [video](https://www.youtube.com/watch?v=V_ifbn-tuoY) for a short summary.

The implementation is intended as a proof of concept instead of a fully-working product. Several effects and features of Unity are not working with our curved space implementation ([see below for details](#potential-improvements)).

## Implementation in a nutshell

### Transformation of mesh vertices and normals

Compared to rendering in the traditional way (in Euclidean geometry), the following needs to be changed when mesh vertices are projected to clipping space:
1. Scale the scene. The way we map vertices defined in Euclidean geometry to curved geometries tries to keep their distance from the origin. Scaling the scene before this transformation can control how curved the scene looks. Additionally, as the mapping to Elliptic space is periodic with period <img src="https://render.githubusercontent.com/render/math?math=\pi">, it is beneficial to scale down the scene to fit in a (Euclidean) sphere with radius <img src="https://render.githubusercontent.com/render/math?math=\pi"> when visualizing in Elliptic space.
2. 3D Euclidean coordinates need to be transformed to 4D embedding space coordinates of the non-Euclidean geometry.
3. Replace the Model, View and Projection matrices.

Performance-wise the most efficient solution is to scale the vertices of each mesh and apply the mapping to curved geometry only once and save the new vertex values in the vertex buffer (note that in Unity vertex data is 3D by default, however, we need to save the 4D embedding space coordinates), and to compute Non-Euclidean transformation matrices in Unity scripts and upload them once as shader uniform variables (if the global scale is not 1, the transformation component of the model and view matrices need to be adapted as well). In Unity, this approach is rather cumbersome and it may affect almost everything else in a game (for instance, changing the global scale would affect every script and physical parameter related to animation; procedural generation becomes more difficult etc.).

All these troubles can be avoided if we shift the entire computation to the vertex shader, which is exactly what this implementation does. This way, the only thing that needs to be modified in Unity is the shader code for rendering - which always has to be modified in any possible solutions -, we can keep the original vertex buffers, use the standard matrices, animation scripts and so on. The only drawback is that the vertex shader becomes somewhat more computationally intensive.

### Shading

Correct shading calculation in the curved spaces require only [three small modifications in the traditional shading routines](https://diglib.eg.org/handle/10.2312/egs20211010): the definition of the dot product and the computation of direction vectors and distances.

### Animation

The theoretically correct animation would map vertices to the curved space and perform the animation there, which involves the slight modification of the physical simulation and rewriting every Unity script that animates objects (camera movement, avatar control etc., even animation curves need to be transformed). However, if we want to keep the required modifications in an existing game minimal, we can perform the animation in Euclidean geometry and only visualize the result as if we were in curved space. This way only the visualization shaders need to be modified, so we picked this method. 

As curved spaces are locally Euclidean, the frame-by-frame difference between the two approaches is almost negligible. The difference may become significant after players have traveled a longer distance - however, they will barely notice that they ended up in a position that is different from what the theory suggests.

### Spherical vs. Elliptic geometry

The main difference between Spherical and Elliptic geometry is that points of Spherical geometry are points of the unit hyper-sphere, whereas points of Elliptic geometry are *diameters*. Treating points as diameters is needed to keep the validity of the axiom stating that *"two distinct points unambiguously define a line"*; this is violated in Spherical geometry.

From the technical point of view, this means that for Spherical geometry we need to render the transformed geometry only once, and for Elliptic geometry everything is rendered twice: first the transformed points and then their antipodes. As the main draw call loop is hidden from the game developer in Unity, the easiest way to render an object twice is to use *geometry shaders* to duplicate every triangle, so we picked this approach. Other options would be either to call `Camera.render()` manually in scripts, or to have a second camera and merge the two views. However, both methods would require additional scripting and more work when integrating the non-Euclidean rendering package to an existing game.

## How to use it in your Unity game

- *Installation*: copy the **Assets/NonEuclidean** folder to the **Assets** folder of your Unity project.
- *Usage*: use the shader in **Assets/NonEuclid/NonEuclideanGeometry.shader** to render in non-Euclidean geometry. 

You may find example materials under **Assets/NonEuclidean/Materials** that change the look of individual objects and also helper scripts in **Assets/NonEuclidean/Scripts** to render the entire scene in the selected curved geometry.

### Curved geometry materials

Newly created materials need to use the `NonEuclid/NonEuclideanGeomerty` shader. `Curve=1` corresponds to Elliptic geometry, whereas `Curve=-1` to Hyperbolic (`Curve=0` gives back the traditional Euclidean geometry). The `globalScale` parameter controls how curved the space looks like. For typical, smaller scenes values between `0.01` and `0.1` usually give nice results. 

**Assets/NonEuclidean/Materials** contains example materials, `SampleScene.unity` demonstrates their usage.

### Render everything uniformly using Shader Replacement

In Unity, [Shader Replacement](https://docs.unity3d.com/2021.2/Documentation/Manual/SL-ShaderReplacement.html) allows a camera object to render every object with the same shader, instead of the shaders of the materials that are assigned to the objects. This is the fastest way to change the look of the entire scene as we don't need to replace every single material one by one. On the other hand, the variety of rendering effects is lost - unless one uses an "uber shader" as shader replacement.

You may use the `GeometryControl.cs` script on a camera to render the scene in Euclidean, Elliptic or Hyperbolic geometry using shader replacement. `SwitchGeometry.cs` is a very simple script to switch between geometries and control their scale with keyboard keys. `MultiView.cs` renders the scene with the same camera settings in every geometry in split-screen. `SampleSceneShaderReplacement.unity` shows how to setup the camera for shader replacement and demonstrates the helper scripts.

## Potential improvements

The rendering system of Unity has many functionalities which have not been adapted to our curved space rendering code. These include:

- Support other rendering paths. We implemented the effects only for forward rendering, which is the most common one. Deferred rendering shaders may be implemented identically.
- Support other renderers. Our implementation assumes OpenGL, however, with a slight modification of the projection matrix the effects could be ported to other renderers (e.g. DirectX).
- Shadows. The shadow mapping algorithm works identically in Elliptic/Hyperbolic geometries. However, Unity uses screen-space shadow maps in many cases (e.g. for the main light source by default), which means that the shadow map that is generated automatically under the hood - *assuming Euclidean geometry* - and that game developers can access in their custom shaders contains whether the surface point is shadowed or not instead of distance values in light-space (as for ordinary shadow maps), which are inaccessible. Pretending that we are still in Euclidean geometry does not work here, as different surface points may be visible in different geometries from the same viewpoint. On the other hand, Unity allows to set a custom screen-space shadow shader, which may be used to generate the screen-space shadow map assuming curved geometry.
- Support other rendering modes. We implemented an "uber fragment shader" that supports various shading models such as diffuse color, specular reflections, emission etc. Additional effects like image-based lighting, transparency, billboards, normal/displacement mapping, etc. can be implemented identically, using the same, non-Euclidean vertex shader with different fragment shaders. 
