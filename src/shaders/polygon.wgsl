/// Constants
let PI: f32 = 3.14159265;

// TODO: Update perspective() to not require this!
//let OPENGL_TO_WGPU: mat4x4<f32> = mat4x4<f32>(
//    vec4<f32>(1.0, 0.0, 0.0, 0.0),
//    vec4<f32>(0.0, 1.0, 0.0, 0.0),
//    vec4<f32>(0.0, 0.0, 0.5, 0.5),
//    vec4<f32>(0.0, 0.0, 0.0, 1.0),
//);


/// Types & Uniforms

[[block]]
struct Time {
    secs: f32;
};
[[group(0), binding(0)]]
var<uniform> time: Time;

[[block]]
struct Camera {
    view_pos: vec4<f32>;
    view_proj: mat4x4<f32>;
};
[[group(0), binding(1)]]
var<uniform> camera: Camera;


struct VertexOutput {
    [[builtin(position)]] clip_position: vec4<f32>;
    [[location(0)]] uv: vec2<f32>;
};

/// Utility Functions

// TODO: Figure out whether it is better or worse to use control flow instructions (if, switch, etc.)
// Then re-write the utilities below to all use if/switch/... or the select/zip_n family of functions.

fn radians(d: f32) -> f32 {
    return d * PI / 180.0;
}

// Checks if `i` is even.
fn is_even(i: u32) -> bool {
    return (i & 1u) == 0u;
}

// Zips (interleaves) two sequences.
fn zip_2(even: u32, odd: u32, i: u32) -> u32 {
    return select(odd, even, is_even(i));
}

// Zips (interleaves) three sequences.
fn zip_3(mod_0: u32, mod_1: u32, mod_2: u32, i: u32) -> u32 {
    switch (i % 3u) {
        default: {
            return mod_0;
        }
        case 1u: {
            return mod_1;
        }
        case 2u: {
            return mod_2;
        }
    }
}

// XY coordinates of a regular `n`-gon rotated by `a`, at index `i`.
fn reg_poly_xy(n: u32, i: u32, a: f32) -> vec2<f32> {
    let b = ((PI * 2.0) / f32(n)) * f32(i) + a;
    return vec2<f32>(cos(b), sin(b));
}

// Index for fan-triangulating a convex `n`-gon at `i`.
fn fan_i(i: u32) -> u32 {
    let m = i % 3u;
    return 
      // [0, 0, 0, 1, 1, 1, 2, 2, 2, ..]
      (i / 3u) *
      // [0, 1, 1, 0, 1, 1, 0, 1, 1, ..]
      ((m + 1u) / 2u) +
      // [0, 1, 2, 0, 1, 2, 0, 1, 2, ..]
      m;
    // = [0, 1, 2, 0, 2, 3, 0, 3, 4, ..]
}

// Vertex index chain for strip-triangulating a convex `n`-gon.
fn poly_strip(n: u32, i: u32) -> u32 {
    return zip_2(
        // [0, 0, n-1, n-1, n-2, n-2, ..]
        (n - i / 2u) % n,
        // [1, 1, 2, 2, 3, 3, ..]
        (i + 1u) / 2u,
        i,
    );
}

// Index for strip-triangulating a convex `n`-gon at `i`.
fn poly_strip_i(n: u32, i: u32) -> u32 {
    let t0 = i / 3u;
    let t2 = t0 + 2u;
    return poly_strip(n, zip_3(
        zip_2(t0, t2, t0),
        t0 + 1u,
        zip_2(t2, t0, t0),
        i,
    ));
}

// Convert from UV coords (0..1) to normalised coords (-1..1).
fn to_xy(uv: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(
        uv.x * 2.0 - 1.0,
        uv.y * 2.0 - 1.0,
    );
}

// Convert from XY coords (-1..1) to UV coords (0..1).
fn to_uv(xy: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(
        (xy.x + 1.0) / 2.0,
        (xy.y + 1.0) / 2.0,
    );
}

fn to_vec3(v: vec4<f32>) -> vec3<f32> {
    return vec3<f32>(v.x / v.w, v.y / v.w, v.z / v.w);
}

// Lok from `eye` at `dir`, with `up` facing up.
// https://docs.rs/cgmath/0.18.0/src/cgmath/matrix.rs.html#366-378
fn look_to(eye: vec3<f32>, dir: vec3<f32>, up: vec3<f32>) -> mat4x4<f32> {
    let f = normalize(dir);
    let s = normalize(cross(f, up));
    let u = cross(s, f);

    return mat4x4<f32>(
        vec4<f32>(s.x, u.x, -f.x, 0.0),
        vec4<f32>(s.y, u.y, -f.y, 0.0),
        vec4<f32>(s.z, u.z, -f.z, 0.0),
        vec4<f32>(-dot(eye, s), -dot(eye, u), dot(eye, f), 1.0),
    );
}

fn look_at(eye: vec3<f32>, center: vec3<f32>, up: vec3<f32>) -> mat4x4<f32> {
    return look_to(eye, center - eye, up);
}

fn look_at_o(eye: vec3<f32>) -> mat4x4<f32> {
    return look_at(eye, vec3<f32>(0.0, 0.0, 0.0), vec3<f32>(0.0, 1.0, 0.0));
}

fn perspective(fovy: f32, aspect: f32, near: f32, far: f32) -> mat4x4<f32> {
    let d = near - far;
    let f = 1.0 / tan(radians(fovy) / 2.0);
    return mat4x4<f32>(
        vec4<f32>(f / aspect, 0.0, 0.0, 0.0),
        vec4<f32>(0.0, f, 0.0, 0.0),
        vec4<f32>(0.0, 0.0, (near + far) / d, -1.0),
        vec4<f32>(0.0, 0.0, (near * far * 2.0) / d, 0.0),
    );
}

fn view_proj() -> mat4x4<f32> {
    return (
        // OPENGL_TO_WGPU *
        perspective(35.0, 1.333333, 0.0001, 1000.0)
    ) * look_at_o(vec3<f32>(
        sin(time.secs * PI / 8.0) * 4.0,
        0.0,
        cos(time.secs * PI / 8.0) * 4.0,
    ));
}

// Vertex Shader

[[stage(vertex)]]
fn vs_main(
    [[builtin(vertex_index)]] idx: u32,
) -> VertexOutput {
    let xy = reg_poly_xy(4u, poly_strip_i(4u, idx), time.secs * 2.0);

    var v: VertexOutput;
    v.uv = to_uv(xy);
    v.clip_position = view_proj() * vec4<f32>(xy, 0.0, 1.0);
    return v;
}

// Fragment Shader

[[stage(fragment)]]
fn fs_main(in: VertexOutput) -> [[location(0)]] vec4<f32> {
    return vec4<f32>(in.uv, 0.0, 1.0);
}
