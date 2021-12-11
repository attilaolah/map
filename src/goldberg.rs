use std::ops::Range;

use cgmath::{Angle, Matrix4, Rad};
use wgpu::util::DeviceExt;

// Triangle:
//
// Number of edges / vertices:
const TRI_V: u32 = 3;

// Pentagon:
//
// Number of edges / vertices:
const PEN_V: u32 = 5;
// Number of triangles:
const PEN_T: u32 = PEN_V - 2;
// Total number of vertices when triangulated:
const PEN_VT: u32 = TRI_V * PEN_T;

// Hexagon:
//
// Number of edges / vertices:
const HEX_V: u32 = 6;
// Numwber of triangles:
const HEX_T: u32 = HEX_V - 2;
// Total number of vertices when triangulated:
const HEX_VT: u32 = TRI_V * HEX_T;

// Icosahedron:
//
// Number of vertices:
const ICO_V: u32 = 12;

// Truncated icosahedron:
//
// Number of pentagonal faces:
const TRU_FP: u32 = ICO_V;
// Number of hexagonal faces:
const TRU_FH: u32 = 20;

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
    transform_pen: [[[f32; 4]; 4]; 12], // TRU_FP
    transform_hex: [[[f32; 4]; 4]; 20], // TRU_FH
}

impl Goldberg {
    pub fn new(device: &wgpu::Device, texture_format: wgpu::TextureFormat) -> Self {
        let uniform = Uniform {
            subdiv: 1,
            _pad: [0, 0, 0],
        };
        let static_data = StaticData {
            transform_pen: (0..12)
                .map(Self::pen_tr)
                .collect::<Vec<_>>()
                .try_into()
                .unwrap(),
            transform_hex: (0..20)
                .map(Self::hex_tr)
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
        println!("{}", self.uniform.subdiv + 1);
        self.uniform.subdiv += 1;
        self.buf_dirty = true;
        true
    }

    pub fn zoom_out(&mut self) -> bool {
        if self.uniform.subdiv > 0 {
            println!("{}", self.uniform.subdiv - 1);
            self.uniform.subdiv -= 1;
            self.buf_dirty = true;
            true
        } else {
            false
        }
    }

    fn pen_vertices() -> Range<u32> {
        0..PEN_VT + 1
    }

    fn hex_vertices(&self) -> Range<u32> {
        if self.uniform.subdiv <= 1 {
            return 0..HEX_VT + 1;
        }
        0..HEX_VT + 1 // todo!()
    }

    fn pen_instances() -> Range<u32> {
        0..TRU_FP + 1
    }

    fn hex_instances() -> Range<u32> {
        0..TRU_FH + 1
    }

    fn pen_tr(i: u32) -> [[f32; 4]; 4] {
        let mut m = Matrix4::from_angle_y(Rad(0.0));

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

    fn hex_tr(i: u32) -> [[f32; 4]; 4] {
        // TODO: Implement the rest of the transforms!
        let mut m = Matrix4::from_angle_y(Rad::full_turn() * (i as f32 / 5.0 + 0.1))
            * Matrix4::from_angle_x((Rad::turn_div_4() - Rad::atan(0.5)) / 2.0)
            * Matrix4::from_angle_y(Rad::turn_div_6() / 2.0);
        if (i / 10) & 1 == 1 {
            m = m * Matrix4::from_angle_x((Rad::turn_div_4() - Rad::atan(0.5)) / 2.0);
        }
        if i >= 10 {
            m = Matrix4::from_angle_x(Rad::turn_div_2()) * m;
        }

        m.into()
    }
}
