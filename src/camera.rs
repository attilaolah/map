use cgmath::{perspective, Deg, Matrix4, Point3, Rad, SquareMatrix, Vector3};

pub const OPENGL_TO_WGPU_MATRIX: Matrix4<f32> = Matrix4::new(
    1.0, 0.0, 0.0, 0.0, //
    0.0, 1.0, 0.0, 0.0, //
    0.0, 0.0, 0.5, 0.0, //
    0.0, 0.0, 0.5, 1.0, //
);

pub struct Camera {
    pub pos: Point3<f32>,
    pub proj: Projection,
    pub uniform: Uniform,
}

pub struct Projection {
    aspect: f32,
    fovy: Rad<f32>,
    znear: f32,
    zfar: f32,
}

#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Uniform {
    view_pos: [f32; 4],
    view_proj: [[f32; 4]; 4],
}

impl Camera {
    pub fn new(distance: f32, w: u32, h: u32) -> Self {
        let mut cam = Self {
            pos: Point3::new(0.0, 0.0, distance),
            proj: Projection::new(w, h, Deg(35.0), 0.0001, 1000.0),
            uniform: Uniform::new(),
        };
        cam.update_view_proj();
        cam
    }

    pub fn resize(&mut self, w: u32, h: u32) {
        self.proj.aspect = w as f32 / h as f32;
        self.update_view_proj();
    }

    fn update_view_proj(&mut self) {
        self.uniform.view_pos = self.pos.to_homogeneous().into();
        self.uniform.view_proj = (self.proj.calc_matrix() * self.calc_matrix()).into();
    }

    fn calc_matrix(&self) -> Matrix4<f32> {
        Matrix4::look_at_rh(self.pos, Point3::new(0.0, 0.0, 0.0), Vector3::unit_y())
    }
}

impl Projection {
    fn new<F: Into<Rad<f32>>>(w: u32, h: u32, fovy: F, znear: f32, zfar: f32) -> Self {
        Self {
            aspect: w as f32 / h as f32,
            fovy: fovy.into(),
            znear,
            zfar,
        }
    }

    fn calc_matrix(&self) -> Matrix4<f32> {
        OPENGL_TO_WGPU_MATRIX * perspective(self.fovy, self.aspect, self.znear, self.zfar)
    }
}

impl Uniform {
    fn new() -> Self {
        Self {
            view_pos: [0.0; 4],
            view_proj: cgmath::Matrix4::identity().into(),
        }
    }
}
