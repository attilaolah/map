[[block]]
struct Camera {
    view_pos: vec4<f32>;
    view_proj: mat4x4<f32>;
};
[[group(0), binding(0)]]
var<uniform> camera: Camera;

struct VertexOutput {
    [[builtin(position)]] clip_position: vec4<f32>;
    [[location(0)]] position: vec2<f32>;
};

// Vertex Shader

[[stage(vertex)]]
fn vs_main(
    [[builtin(vertex_index)]] idx: u32,
) -> VertexOutput {
    var out: VertexOutput;
    let x = f32(1 - i32(idx)) * 0.5;
    let y = f32(i32(idx & 1u) * 2 - 1) * 0.5;
    out.position = vec2<f32>(x, y);

    out.clip_position = camera.view_proj * vec4<f32>(x, y, 0.0, 1.0);
    return out;
}

// Fragment Shader

[[stage(fragment)]]
fn fs_main(in: VertexOutput) -> [[location(0)]] vec4<f32> {
    return vec4<f32>(in.position, 0.0, 1.0);
}
