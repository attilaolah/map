[[block]]
struct Camera {
    view_pos: vec4<f32>;
    view_proj: mat4x4<f32>;
};
[[group(0), binding(0)]]
var<uniform> camera: Camera;

struct VertexOutput {
    [[builtin(position)]] clip_position: vec4<f32>;
    [[location(0)]] uv: vec2<f32>;
};

// UV coordinates for a square.
// Parameter `i` should be in range [0, 5] (inclusive).
fn uv_square(i: u32) -> vec2<f32> {
    return vec2<f32>(
        // [0, 1, 0, 1, 0, 1]
        f32(i & 1u),
        // [0, 1, 1, 1, 0, 0]
        f32(((i + 2u) / 3u) & 1u)
    );
}

// Convert from UV coords (0..1) to normalised coords (-1..1).
fn uv2xy(uv: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(
        uv.x * 2.0 - 1.0,
        uv.y * 2.0 - 1.0,
    );
}

// Vertex Shader

[[stage(vertex)]]
fn vs_main(
    [[builtin(vertex_index)]] idx: u32,
) -> VertexOutput {
    let uv = uv_square(idx % 6u);

    var v: VertexOutput;
    v.uv = uv;
    v.clip_position = camera.view_proj * vec4<f32>(uv2xy(uv), 0.0, 1.0);
    return v;
}

// Fragment Shader

[[stage(fragment)]]
fn fs_main(in: VertexOutput) -> [[location(0)]] vec4<f32> {
    return vec4<f32>(in.uv, 0.0, 1.0);
}
