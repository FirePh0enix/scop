pub const RenderMode = enum {
    color,
    texture,
};

enable_rotation: bool = true,
render_mode: RenderMode = .texture,
rotation_speed: f32 = 0.01,
model_x: f32 = 0.0,
model_y: f32 = 1.0,
model_z: f32 = -4.0,
fov: f32 = 60.0,
move_speed: f32 = 0.2,
window_width: usize = 1280,
window_height: usize = 720,
