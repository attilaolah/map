use std::iter;
use std::time;

use wgpu::util::DeviceExt;
use winit::{
    dpi::PhysicalSize,
    event::{ElementState, KeyboardInput, VirtualKeyCode, WindowEvent},
    window::Window,
};

use crate::camera::Camera;
use crate::goldberg::Goldberg;

pub struct Engine {
    surface: wgpu::Surface,
    device: wgpu::Device,
    queue: wgpu::Queue,
    config: wgpu::SurfaceConfiguration,
    render_pipeline: wgpu::RenderPipeline,

    size: PhysicalSize<u32>,

    cam: Camera,
    cam_buf: wgpu::Buffer,
    cam_dirty: bool,

    created_at: time::Instant,
    time_buf: wgpu::Buffer,

    goldberg: Goldberg,

    uniforms_bind_group: wgpu::BindGroup,
}

#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
struct Time(f32);

impl Time {
    fn between(earlier: time::Instant, later: time::Instant) -> Self {
        Self(later.duration_since(earlier).as_secs_f32())
    }
}

impl Engine {
    pub async fn new(window: &Window) -> Self {
        let size = window.inner_size();

        // The instance is a handle to our GPU.
        // BackendBit::PRIMARY => Vulkan + Metal + DX12 + Browser WebGPU.
        let instance = wgpu::Instance::new(wgpu::Backends::all());
        let surface = unsafe { instance.create_surface(window) };
        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::default(),
                compatible_surface: Some(&surface),
                force_fallback_adapter: false,
            })
            .await
            .unwrap();

        let (device, queue) = adapter
            .request_device(
                &wgpu::DeviceDescriptor {
                    label: None,
                    features: wgpu::Features::empty(),
                    limits: wgpu::Limits::default(),
                },
                None, // trace path
            )
            .await
            .unwrap();

        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format: surface.get_preferred_format(&adapter).unwrap(),
            width: size.width,
            height: size.height,
            present_mode: wgpu::PresentMode::Fifo,
        };
        surface.configure(&device, &config);

        // Time setup:

        let time_buf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Time Buffer"),
            contents: bytemuck::cast_slice(&[Time(0.0)]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        // Camera setup:

        let cam = Camera::new(4.0, size.width, size.height);

        let cam_buf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Camera Buffer"),
            contents: bytemuck::cast_slice(&[cam]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        // Goldberg polyhedron setup:

        let goldberg = Goldberg::new(&device, config.format);

        let uniforms_bind_group_layout =
            device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                entries: &[
                    wgpu::BindGroupLayoutEntry {
                        binding: 0,
                        visibility: wgpu::ShaderStages::VERTEX,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 1,
                        visibility: wgpu::ShaderStages::VERTEX,
                        ty: wgpu::BindingType::Buffer {
                            ty: wgpu::BufferBindingType::Uniform,
                            has_dynamic_offset: false,
                            min_binding_size: None,
                        },
                        count: None,
                    },
                    Goldberg::bind_group_layout_entry(2),
                    Goldberg::bind_group_layout_entry(3),
                ],
                label: Some("uniforms_bind_group_layout"),
            });

        let uniforms_bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout: &uniforms_bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: time_buf.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: cam_buf.as_entire_binding(),
                },
                goldberg.uniform_bind_group_entry(2),
                goldberg.static_data_bind_group_entry(3),
            ],
            label: Some("uniforms_bind_group"),
        });

        // Render pipeline setup:

        let render_pipeline_layout =
            device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("Render Pipeline Layout"),
                bind_group_layouts: &[&uniforms_bind_group_layout],
                push_constant_ranges: &[],
            });

        let render_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("Render Pipeline"),
            layout: Some(&render_pipeline_layout),
            vertex: goldberg.vertex_state(),
            fragment: goldberg.fragment_state(),
            primitive: Goldberg::primitive_state(),
            depth_stencil: None,
            multisample: wgpu::MultisampleState {
                count: 1,
                mask: !0,
                alpha_to_coverage_enabled: false,
            },
        });

        Self {
            surface,
            device,
            queue,
            config,
            render_pipeline,

            size,

            cam,
            cam_buf,
            cam_dirty: false,

            created_at: time::Instant::now(),
            time_buf,

            goldberg,

            uniforms_bind_group,
        }
    }

    pub fn render(&mut self) -> Result<(), wgpu::SurfaceError> {
        let output = self.surface.get_current_texture()?;
        let view = output
            .texture
            .create_view(&wgpu::TextureViewDescriptor::default());

        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("Render Encoder"),
            });

        {
            let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("Render Pass"),
                color_attachments: &[wgpu::RenderPassColorAttachment {
                    view: &view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                        store: true,
                    },
                }],
                depth_stencil_attachment: None,
            });

            render_pass.set_pipeline(&self.render_pipeline);
            render_pass.set_bind_group(0, &self.uniforms_bind_group, &[]);

            self.goldberg.draw_to(&mut render_pass);
        }

        self.queue.submit(iter::once(encoder.finish()));
        output.present();

        Ok(())
    }

    pub fn recover(&mut self) {
        self.resize(self.size);
    }

    pub fn resize(&mut self, new_size: winit::dpi::PhysicalSize<u32>) {
        if new_size.width > 0 && new_size.height > 0 {
            self.size = new_size;
            self.config.width = new_size.width;
            self.config.height = new_size.height;
            self.surface.configure(&self.device, &self.config);

            self.cam.resize(self.config.width, self.config.height);
            self.cam_dirty = true;
        }
    }

    pub fn input(&mut self, event: &WindowEvent) -> bool {
        match event {
            WindowEvent::Resized(physical_size) => {
                self.resize(*physical_size);
                true
            }
            WindowEvent::ScaleFactorChanged { new_inner_size, .. } => {
                // `new_inner_size` is &mut so we have to dereference it twice:
                self.resize(**new_inner_size);
                true
            }
            WindowEvent::KeyboardInput {
                input:
                    KeyboardInput {
                        state: ElementState::Pressed,
                        virtual_keycode: Some(VirtualKeyCode::Plus),
                        ..
                    },
                ..
            } => {
                self.goldberg.zoom_in();
                true
            }
            WindowEvent::KeyboardInput {
                input:
                    KeyboardInput {
                        state: ElementState::Pressed,
                        virtual_keycode: Some(VirtualKeyCode::Minus),
                        ..
                    },
                ..
            } => {
                self.goldberg.zoom_out();
                true
            }
            _ => false,
        }
    }

    pub fn update(&mut self) {
        self.queue
            .write_buffer(&self.time_buf, 0, bytemuck::cast_slice(&[self.lifetime()]));
        if self.cam_dirty {
            self.queue
                .write_buffer(&self.cam_buf, 0, bytemuck::cast_slice(&[self.cam]));
            self.cam_dirty = false;
        }
        self.goldberg.queue_update_if_needed(&self.queue, 0);
    }

    fn lifetime(&self) -> Time {
        return Time::between(self.created_at, time::Instant::now());
    }
}
