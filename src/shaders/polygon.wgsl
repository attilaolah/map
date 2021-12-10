/// Constants
let PI: f32 = 3.141592653589793;
let TAU: f32 = 6.283185307179586;  // = PI * 2.0;

/// Types & Uniforms

[[block]]
struct Time {
    secs: f32;
};
[[group(0), binding(0)]]
var<uniform> time: Time;

[[block]]
struct Camera {
    pos: vec3<f32>;
    aspect: f32;
    fovy: f32;
    znear: f32;
    zfar: f32;
};
[[group(0), binding(1)]]
var<uniform> cam: Camera;


struct VertexOutput {
    [[builtin(position)]] clip_position: vec4<f32>;
    [[location(0)]] uv: vec2<f32>;
};

/// Utility Functions

// TODO: Figure out whether it is better or worse to use control flow instructions (if, switch, etc.)
// Then re-write the utilities below to all use if/switch/... or the select/zip_n family of functions.

fn rad(d: f32) -> f32 {
    return d * PI / 180.0;
}

// Convert from spherical to cartesian coortinates.
// `theta` is away from the +Y axis, `phi` is away from the +Z axis (probably).
fn cart(phi: f32, theta: f32) -> vec3<f32> {
    return vec3<f32>(
        sin(phi) * sin(theta),
        cos(theta),
        cos(phi) * sin(theta),
    );
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
    let b = (TAU / f32(n)) * f32(i) + a;
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

fn rot_x(by: f32) -> mat3x3<f32> {
    let s = sin(by);
    let c = cos(by);
    return mat3x3<f32>(
        vec3<f32>(1.0, 0.0, 0.0),
        vec3<f32>(0.0, c, s),
        vec3<f32>(0.0, -s, c),
    );
}

fn rot_y(by: f32) -> mat3x3<f32> {
    let s = sin(by);
    let c = cos(by);
    return mat3x3<f32>(
        vec3<f32>(c, 0.0, -s),
        vec3<f32>(0.0, 1.0, 0.0),
        vec3<f32>(s, 0.0, c),
    );
}

fn rot_z(by: f32) -> mat3x3<f32> {
    let s = sin(by);
    let c = cos(by);
    return mat3x3<f32>(
        vec3<f32>(c, s, 0.0),
        vec3<f32>(-s, c, 0.0),
        vec3<f32>(0.0, 0.0, 1.0),
    );
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
    let f = 1.0 / tan(fovy / 2.0);
    return mat4x4<f32>(
        vec4<f32>(f / aspect, 0.0, 0.0, 0.0),
        vec4<f32>(0.0, f, 0.0, 0.0),
        vec4<f32>(0.0, 0.0, (near + far) / d, -1.0),
        vec4<f32>(0.0, 0.0, (near * far * 2.0) / d, 0.0),
    );
}

fn view_proj() -> mat4x4<f32> {
    return (
        // OPENGL_TO_WGPU_MATRIX
        // Doesn't seem to be necessary though.
        // mat4x4<f32>(
        //     vec4<f32>(1.0, 0.0, 0.0, 0.0),
        //     vec4<f32>(0.0, 1.0, 0.0, 0.0),
        //     vec4<f32>(0.0, 0.0, 0.5, 0.5),
        //     vec4<f32>(0.0, 0.0, 0.0, 1.0),
        // ) *
        perspective(cam.fovy, cam.aspect, cam.znear, cam.zfar)
    ) * look_at_o(vec3<f32>(
        // Rotate around the Y axis.
        sin(time.secs / 8.0) * 4.0,
        2.0, // sin(time.secs / 2.0) * 2.0,
        cos(time.secs / 8.0) * 4.0,
    ));
}

// Triangle:
let TRI_V: u32 = 3u;  // number of edges / vertices

// Pentagon:
// https://mathworld.wolfram.com/RegularPentagon.html
let PEN_V: u32 = 5u; // number of edges / vertices
let PEN_T: u32 = 3u; // = PEN_V - 2u; number of triangles
let PEN_VT: u32 = 9u; // = PEN_T * TRI_V; total number of vertices when triangulated
// Edge scale factor, i.e. the edge of a pentagon with circumradius = 1.
let PEN_ES: f32 = 1.1755705045849463; // = 10.0 / sqrt(50.0 + 10.0 * sqrt(5.0));

// Hexagon:
// https://mathworld.wolfram.com/RegularHexagon.html
let HEX_V: u32 = 6u; // number of edges / vertices
let HEX_T: u32 = 4u; // = HEX_V - 2u; number of triangles
let HEX_VT: u32 = 12u; // = HEX_T * TRI_V; total number of vertices when triangulated

// Icosahedron:
let ICO_F: u32 = 20u; // number of faces
let ICO_E: u32 = 30u; // number of faces
let ICO_V: u32 = 12u; // number of vertices
// Smallest angle between any two vertex vectors.
let ICO_AV: f32 = 1.1071487177940904; // = PI / 2.0 - atan(0.5);

// Truncated Icosahedron (Goldberg):
// https://mathworld.wolfram.com/TruncatedIcosahedron.html
let TRU_VP: u32 = 108u; // = ICO_V * PEN_VT; total number of vertices of triangulated pentagonal faces
// Edge scale factor, i.e. the edge of a truncated icosahedron with circumradius = 1.
let TRU_ES: f32 = 0.40354821233519766; // = 4.0 / sqrt(58.0 + 18.0 * sqrt(5.0))
// Latitudes of vertices:
let TRU_LAT_0: f32 = 0.35040541284731597; // = asin(TRU_ES / PEN_ES);
let TRU_LAT_1: f32 = 0.75674330494677440; // = ICO_AV - TRU_LAT_0;
let TRU_LAT_2: f32 = 1.02932537965617590; // TODO: Just an estimate for now.
let TRU_LAT_3: f32 = 1.39830543682029700; // TODO: Just an estimate for now.
let TRU_LAT_4: f32 = 1.74328721676949620; // TODO: Just an estimate for now.

fn goldberg_pentagons(idx: u32) -> VertexOutput {
    // "Instance" ID:
    let ins = idx / PEN_VT;
    // Index modulo XY+XZ plane symmetry.
    let ins_2 = ins % (ICO_V / 2u);
    // Intentionally shadow the global index with the local one:
    let idx = idx % PEN_VT;

    let pole = ins_2 == 0u;
    let flip = ins != ins_2;

    let idv = poly_strip_i(PEN_V, idx);

    let v = cart(
        TAU / 5.0 * f32(idv) + select(PI / 5.0, 0.0, pole),
        TRU_LAT_0 * (abs(cos(time.secs)) * 0.5 + 0.5),
    );

    // [1..5] X-axis rotation:
    let v = select(rot_x(ICO_AV) * v, v, pole);
    // [1..5] Y-axis rotation:
    let v = select(rot_y(
        // Technically the "-1u" is not necessary.
        // It makes the pentagon with index 1 face towards the camera.
        PI / f32(PEN_V) * f32(ins - 1u) * 2.0
    ) * v, v, pole);

    // [6..11] XY+XZ-plane symmetry (flip):
    let v = select(v, vec3<f32>(v.x, -v.y, -v.z), flip);

    var out: VertexOutput;
    out.uv = to_uv(v.xy);
    out.clip_position = view_proj() * vec4<f32>(v, 1.0);
    return out;
}

fn goldberg_hexagons(idx: u32) -> VertexOutput {
    // "Instance" ID:
    let ins = idx / HEX_VT;
    // Index modulo XY+XZ plane symmetry.
    let ins_2 = ins % 10u;
    // Index within a single ring of hexagons
    let ins_r = ins % 5u;
    // Intentionally shadow the global index with the local one:
    let idx = idx % HEX_VT;

    // TODO: debug!
    if (ins >= 6u) { var v: VertexOutput; v.uv = vec2<f32>(0.0, 0.0); v.clip_position = vec4<f32>(0.0, 0.0, 0.0, 1.0); return v; }

    let flip = ins > 10u;

    // Find the vertex index for the current vertex:
    let idv = poly_strip_i(HEX_V, idx);
    // Select the "row" based on the index.
    // Drawing the hexagon as it would be drawn in 2D, start from the right, go counter-clockwise.
    // [0, 0, 0, 2, 2, 2, ..]
    let row_12 = (idv / 3u) * 2u;
    // [1, 0, 0, 1, 2, 2, ..]
    let row = zip_3(1u, row_12, row_12, idv);

    // Start counting from twice the rowindex.
    // Ring 0 rows are [0, 1, 2], ring 1 rows are [2, 3, 4].
    //let row = ins_r * 2u + row;

    // ROWS:
    var lat = 0.0;
    switch (row) {
        case 0u: { lat = TRU_LAT_0; }
        case 1u: { lat = TRU_LAT_1; }
        case 2u: { lat = TRU_LAT_2; }
        case 3u: { lat = TRU_LAT_3; }
        default: { lat = TRU_LAT_4; }
    }

    // TODO: [3, 3, 0, 0, 1, 2]

    var lon = TAU * f32(ins_r) / 5.0;
    // TODO!
    switch (idv) {
        case 0u: { lon = lon + 0.0; }
        case 1u: { lon = lon + 0.0; }
        case 2u: { lon = lon - PI * 0.4; }
        case 3u: { lon = lon - PI * 0.4; }
        case 4u: { lon = lon - PI * 0.4 + 0.2; } // TODO!
        default: { lon = lon - 0.2; } // TODO!
    }

    // Draw the hexagon in x/y coords.
    let v = cart(lon, lat);

    // [6..11] XY+XZ-plane symmetry (flip):
    let v = select(v, vec3<f32>(v.x, -v.y, -v.z), flip);

    var out: VertexOutput;
    out.uv = to_uv(v.xy);
    out.clip_position = view_proj() * vec4<f32>(v, 1.0);
    return out;
}

// The Vertex Shader

[[stage(vertex)]]
fn vs_main(
    [[builtin(vertex_index)]] idx: u32,
) -> VertexOutput {
    if (idx < TRU_VP) {
        return goldberg_pentagons(idx);
    } else {
        return goldberg_hexagons(idx - TRU_VP);
    }
}

// The Fragment Shader

[[stage(fragment)]]
fn fs_main(in: VertexOutput) -> [[location(0)]] vec4<f32> {
    return vec4<f32>(in.uv, 0.0, 1.0);
}
