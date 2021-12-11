use cgmath::{Deg, Point3, Rad};

#[repr(C)]
#[derive(Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Camera {
    pos: [f32; 3], // vec3<f32>
    aspect: f32,
    fovy: f32, // in radians
    znear: f32,
    zfar: f32,
    _pad: u32,
}

impl Camera {
    pub fn new(distance: f32, w: u32, h: u32) -> Self {
        let fovy: Rad<f32> = Deg(35.0).into();
        Self {
            pos: Point3::new(0.0, 0.0, distance).into(),
            aspect: w as f32 / h as f32,
            fovy: fovy.0,
            znear: 0.0001,
            zfar: 1000.0,
            _pad: 0,
        }
    }

    pub fn resize(&mut self, w: u32, h: u32) {
        self.aspect = w as f32 / h as f32;
    }
}
