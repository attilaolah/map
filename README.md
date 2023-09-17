# The Map Project

Third implementation, based on the [Bevy engine].

For now, this repo is a toy project exploring 3D rendering, map projections,
and eventually other fun things, including smart contracts.

### Some hystory

- The initial implementation was using Godot 3.x. This was working OK but Godot
  back then did not support compute shaders, so I started to look for something
  more flexible. I also didn't really need the UI since I was not going to edit
  static resources too much.
- The second implementation was started using pure WebGPU. This kind of worked,
  but I had the idea of doing pretty much all the work inside the shader. This
  lead to some pretty complex code, and eventually I'd have to load external
  resources anyway, so I decided to start looking for some engine anyway. But I
  did not want to go back to scripting, so I looked for a Rust engine.
- This is how I learned about [Bevy][Bevy engine], which is the engine used in
  this third implementation.

[Bevy engine]: https://bevyengine.org
