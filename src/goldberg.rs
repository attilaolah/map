use std::ops::Range;

use cgmath::{Angle, Matrix4, Rad};
use wgpu::util::DeviceExt;

// Regular triangle.
struct Triangle {}
impl Triangle {
    fn num_vertices() -> u32 {
        3
    }
}

struct Pentagon {
    r: f32,
}
impl Pentagon {
    fn new(r: f32) -> Self {
        Self { r }
    }
    fn with_edge(e: f32) -> Self {
        Self {
            r: e / Self::new(1.0).edge(),
        }
    }

    fn edge(&self) -> f32 {
        self.r * 10.0 / (50.0 + 10.0 * 5f32.sqrt()).sqrt()
    }
    fn inscribed_radius(&self) -> f32 {
        //((50.0 + 10 * 5f32.sqrt())* (25.0 + 10.0 * 5f32.sqrt())).sqrt()
        self.edge() * (25.0 + 10.0 * 5f32.sqrt()).sqrt() / 10.0
    }

    fn num_vertices() -> u32 {
        5
    }
    fn num_triangles() -> u32 {
        Self::num_vertices() - 2
    }
    fn tri_vertices() -> u32 {
        Self::num_triangles() * Triangle::num_vertices()
    }
}

struct Hexagon {
    r: f32,
}
impl Hexagon {
    fn new(r: f32) -> Self {
        Self { r }
    }
    fn with_edge(e: f32) -> Self {
        Self {
            r: e / Self::new(1.0).edge(),
        }
    }

    fn edge(&self) -> f32 {
        self.r
    }
    fn inscribed_radius(&self) -> f32 {
        self.r * 3f32.sqrt() / 2.0
    }

    fn num_vertices() -> u32 {
        6
    }
    fn num_triangles() -> u32 {
        Self::num_vertices() - 2
    }
    fn tri_vertices() -> u32 {
        Self::num_triangles() * Triangle::num_vertices()
    }
}

// Icosahedron:
struct Icosahedron {}

impl Icosahedron {
    fn num_vertices() -> u32 {
        12
    }
}

struct TruncatedIcosahedron {
    r: f32,
}
impl TruncatedIcosahedron {
    fn new(r: f32) -> Self {
        Self { r }
    }

    fn edge(&self) -> f32 {
        self.r * 4.0 / (58.0 + 18.0 * 5f32.sqrt()).sqrt()
    }

    /// Distance between the origin and the midpoint of an edge.
    fn edge_midpoint_radius(&self) -> f32 {
        (1.0 - self.edge() * self.edge() / 4.0).sqrt()
    }

    /// Angle between a pentagonal face's centre and the midpoint of an edge on that face.
    fn pentagon_edge_angle() -> Rad<f32> {
        Rad::asin(
            Pentagon::with_edge(Self::new(1.0).edge()).inscribed_radius()
                / Self::new(1.0).edge_midpoint_radius(),
        )
    }

    /// Angle between a hexagonal face's centre and the midpoint of an edge on that face.
    fn hexagon_edge_angle() -> Rad<f32> {
        Rad::asin(
            Hexagon::with_edge(Self::new(1.0).edge()).inscribed_radius()
                / Self::new(1.0).edge_midpoint_radius(),
        )
    }

    /// Angle between centre points of neighbouring pentagonal and hexagonal faces.
    fn pentagon_hexagon_angle() -> Rad<f32> {
        Self::pentagon_edge_angle() + Self::hexagon_edge_angle()
    }

    /// Angle between centre points of neighbouring hexagonal faces.
    fn hexagon_hexagon_angle() -> Rad<f32> {
        Self::hexagon_edge_angle() * 2.0
    }

    /// Number of pentagonal faces.
    fn num_pentagons() -> u32 {
        Icosahedron::num_vertices()
    }

    /// Number of hexagonal faces.
    fn num_hexagons() -> u32 {
        20
    }
}

pub struct Goldberg {
    uniform: Uniform,

    buf: wgpu::Buffer,
    buf_static: wgpu::Buffer,

    shader: wgpu::ShaderModule,
    fragment_state_targets: [wgpu::ColorTargetState; 1],

    buf_dirty: bool,
}

#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
struct Uniform {
    // Subdivision level. 0 = icosahedron, 1 = truncated icosahedron.
    subdiv: u32,
    _pad: [u32; 3],
}

#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
struct StaticData {
    // Transformations to apply to instances of pentagonal and hexagonal faces.
    // This don't change at runtime, instead these are precomputed only once on startup.
    transform_pen: [[[f32; 4]; 4]; 12], // TruncatedIcosahedron::num_pentagons()
    transform_hex: [[[f32; 4]; 4]; 20], // TruncatedIcosahedron::num_hexagons()
}

impl Goldberg {
    pub fn new(device: &wgpu::Device, texture_format: wgpu::TextureFormat) -> Self {
        let uniform = Uniform {
            subdiv: 1,
            _pad: [0, 0, 0],
        };
        let static_data = StaticData {
            transform_pen: (0..TruncatedIcosahedron::num_pentagons())
                .map(Self::pen_transform)
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
            transform_hex: (0..TruncatedIcosahedron::num_hexagons())
                .map(Self::hex_transform)
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
        };
        Self {
            uniform,
            buf: device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("Goldberg Buffer (dynamic)"),
                contents: bytemuck::cast_slice(&[uniform]),
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            }),
            buf_static: device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: Some("Goldberg Buffer (static data)"),
                contents: bytemuck::cast_slice(&[static_data]),
                usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            }),
            shader: device.create_shader_module(&wgpu::ShaderModuleDescriptor {
                label: Some("Goldberg Shader"),
                source: wgpu::ShaderSource::Wgsl(include_str!("shaders/goldberg.wgsl").into()),
            }),
            fragment_state_targets: [wgpu::ColorTargetState {
                format: texture_format,
                blend: Some(wgpu::BlendState {
                    color: wgpu::BlendComponent::REPLACE,
                    alpha: wgpu::BlendComponent::REPLACE,
                }),
                write_mask: wgpu::ColorWrites::ALL,
            }],
            buf_dirty: false,
        }
    }

    pub fn bind_group_layout_entry(binding: u32) -> wgpu::BindGroupLayoutEntry {
        wgpu::BindGroupLayoutEntry {
            binding,
            visibility: wgpu::ShaderStages::VERTEX,
            ty: wgpu::BindingType::Buffer {
                ty: wgpu::BufferBindingType::Uniform,
                has_dynamic_offset: false,
                min_binding_size: None,
            },
            count: None,
        }
    }

    pub fn uniform_bind_group_entry(&self, binding: u32) -> wgpu::BindGroupEntry {
        wgpu::BindGroupEntry {
            binding,
            resource: self.buf.as_entire_binding(),
        }
    }

    pub fn static_data_bind_group_entry(&self, binding: u32) -> wgpu::BindGroupEntry {
        wgpu::BindGroupEntry {
            binding,
            resource: self.buf_static.as_entire_binding(),
        }
    }

    pub fn vertex_state(&self) -> wgpu::VertexState {
        wgpu::VertexState {
            module: &self.shader,
            entry_point: "vs_main",
            buffers: &[],
        }
    }

    pub fn fragment_state(&self) -> Option<wgpu::FragmentState> {
        Some(wgpu::FragmentState {
            module: &self.shader,
            entry_point: "fs_main",
            targets: &self.fragment_state_targets,
        })
    }
    pub fn primitive_state() -> wgpu::PrimitiveState {
        wgpu::PrimitiveState {
            topology: wgpu::PrimitiveTopology::TriangleList,
            strip_index_format: None,
            front_face: wgpu::FrontFace::Ccw,
            cull_mode: Some(wgpu::Face::Back),
            polygon_mode: wgpu::PolygonMode::Fill,
            clamp_depth: false,
            conservative: false,
        }
    }

    pub fn queue_update_if_needed(&mut self, queue: &wgpu::Queue, offset: wgpu::BufferAddress) {
        if self.buf_dirty {
            queue.write_buffer(&self.buf, offset, bytemuck::cast_slice(&[self.uniform]));
            self.buf_dirty = false;
        }
    }

    pub fn draw_to(&self, render_pass: &mut wgpu::RenderPass) {
        render_pass.draw(Self::pen_vertices(), Self::pen_instances());
        render_pass.draw(self.hex_vertices(), Self::hex_instances());
    }

    pub fn zoom_in(&mut self) -> bool {
        self.uniform.subdiv += 1;
        self.buf_dirty = true;
        true
    }

    pub fn zoom_out(&mut self) -> bool {
        if self.uniform.subdiv > 0 {
            self.uniform.subdiv -= 1;
            self.buf_dirty = true;
            true
        } else {
            false
        }
    }

    fn pen_vertices() -> Range<u32> {
        0..Pentagon::tri_vertices() + 1
    }

    fn hex_vertices(&self) -> Range<u32> {
        if self.uniform.subdiv <= 1 {
            return 0..Hexagon::tri_vertices() + 1;
        }
        0..Hexagon::tri_vertices() + 1 // todo!()
    }

    fn pen_instances() -> Range<u32> {
        0..TruncatedIcosahedron::num_pentagons() + 1
    }

    fn hex_instances() -> Range<u32> {
        TruncatedIcosahedron::num_pentagons()
            ..(TruncatedIcosahedron::num_pentagons() + TruncatedIcosahedron::num_hexagons() + 1)
    }

    fn pen_transform(i: u32) -> [[f32; 4]; 4] {
        let mut m = Matrix4::from_angle_y(Rad(0.0));

        // Order of operations is right-to-left when multiplying.
        if i % 6 != 0 {
            // Technically the "-1" in "i - 1" is not necessary.
            // However, it makes the pentagon with index 1 face towards the camera.
            m = Matrix4::from_angle_y(Rad::full_turn() / 5.0 * (i - 1) as f32)
                * Matrix4::from_angle_x(Rad::turn_div_4() - Rad::atan(0.5))
                * Matrix4::from_angle_y(Rad::turn_div_2() / 5.0)
                * m;
        }
        if i >= 6 {
            m = Matrix4::from_angle_x(Rad::turn_div_2()) * m;
        }

        m.into()
    }

    // TODO: Implement the rest of the transforms!
    fn hex_transform(i: u32) -> [[f32; 4]; 4] {
        // Order of operations is right-to-left when multiplying.
        let mut m = Matrix4::from_angle_y(Rad::full_turn() * (i as f32 / 5.0 + 0.1))
            * Matrix4::from_angle_x(
                TruncatedIcosahedron::pentagon_hexagon_angle()
                    + if (i / 5) & 1 == 1 {
                        TruncatedIcosahedron::hexagon_hexagon_angle()
                    } else {
                        Rad(0.0)
                    },
            )
            * Matrix4::from_angle_y(Rad::turn_div_6() / 2.0);
        if i >= 10 {
            m = Matrix4::from_angle_x(Rad::turn_div_2()) * m;
        }

        m.into()
    }
}
