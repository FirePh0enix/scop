const std = @import("std");
const math = @import("math.zig");
const mlx = @import("mlx");

const Allocator = std.mem.Allocator;
const Matrix4 = math.Matrix4;
const Vector2 = math.Vector2;
const Vector3 = math.Vector3;
const Vector4 = math.Vector4;
const Mesh = @import("Mesh.zig");
const Texture = @import("Texture.zig");
const Settings = @import("Settings.zig");

// TODO: Use SDL instead of MLX

allocator: Allocator,

var the_mesh: Mesh = undefined;
var the_texture: ?Texture = undefined;
var settings: Settings = undefined;
var gfx: Graphics = undefined;
var last_update: i64 = 0;
const time_between_frame = 1_000_000 / 60; // 60 frame per seconds
var rotation_y: f32 = 0.0;

pub fn init(allocator: Allocator, settings_: Settings, mesh_: Mesh, texture_: ?Texture) @This() {
    settings = settings_;
    the_mesh = mesh_;
    the_texture = texture_;
    return .{
        .allocator = allocator,
    };
}

pub fn run(self: *const @This()) !void {
    const mlx_ptr = mlx.mlx_init() orelse std.debug.panic("unable to initialize mlx", .{});
    defer _ = mlx.mlx_destroy_display(mlx_ptr);

    const win_ptr = mlx.mlx_new_window(mlx_ptr, @intCast(settings.window_width), @intCast(settings.window_height), @ptrCast(@constCast("scop"))) orelse std.debug.panic("unable to create the window", .{});
    defer _ = mlx.mlx_destroy_window(mlx_ptr, win_ptr);

    gfx = Graphics.init(mlx_ptr, win_ptr, settings.window_width, settings.window_height, self.allocator) catch std.debug.panic("unable to initialize graphics", .{});
    gfx.render_mode = settings.render_mode;

    const view = Matrix4.translation(.{ .x = 0.0, .y = 0.0, .z = 0.0 });
    const proj = Matrix4.projection(settings.fov, settings.window_width, settings.window_height, 0.001, 1000.0);

    gfx.loadViewMatrix(view);
    gfx.loadProjectionMatrix(proj);

    _ = mlx.mlx_hook(win_ptr, mlx.DestroyNotify, 0, @ptrCast(&onDestroyNotify), null);
    _ = mlx.mlx_hook(win_ptr, mlx.KeyPress, mlx.KeyPressMask, @ptrCast(&onKeyPress), null);
    _ = mlx.mlx_loop_hook(mlx_ptr, @ptrCast(&tick), null);
    _ = mlx.mlx_loop(mlx_ptr);
}

fn tick(_: ?*anyopaque) callconv(.c) void {
    // Limit frame per seconds.
    // TODO: Find a better way, for example waiting for a v-blank or else the CPU will be busy !
    const current_time = std.time.microTimestamp();

    if (current_time - last_update < time_between_frame) {
        return;
    }
    last_update = current_time;

    // const model = Matrix4.model(.{ .x = settings.model_x, .y = settings.model_y, .z = settings.model_z }, .{ .x = 0.0, .y = rotation_y, .z = 0.0 });
    // gfx.loadModelMatrix(model);

    gfx.clear();
    gfx.draw(&the_mesh, .{
        .texture = the_texture,
        .position = .{ .x = settings.model_x, .y = settings.model_y, .z = settings.model_z },
        .rotation = .{ .y = rotation_y },
        .offset = the_mesh.getMiddlePoint(),
    });
    gfx.present();

    if (settings.enable_rotation) {
        rotation_y += settings.rotation_speed;
    }
}

fn onDestroyNotify(_: ?*anyopaque) callconv(.c) void {
    _ = mlx.mlx_loop_end(gfx.mlx_ptr);
}

fn onKeyPress(keycode: c_int, _: ?*anyopaque) callconv(.c) void {
    if (keycode == mlx.XK_F1) {
        if (gfx.render_mode == .color) {
            gfx.render_mode = .texture;
        } else {
            gfx.render_mode = .color;
        }
    }

    if (keycode == mlx.XK_space) {
        settings.enable_rotation = !settings.enable_rotation;
    } else if (keycode == mlx.XK_Left) {
        settings.model_x -= settings.move_speed;
    } else if (keycode == mlx.XK_Right) {
        settings.model_x += settings.move_speed;
    } else if (keycode == mlx.XK_Up) {
        settings.model_y += settings.move_speed;
    } else if (keycode == mlx.XK_Down) {
        settings.model_y -= settings.move_speed;
    } else if (keycode == mlx.XK_Shift_L) {
        settings.model_z -= settings.move_speed;
    } else if (keycode == mlx.XK_Control_L) {
        settings.model_z += settings.move_speed;
    }
}

pub const Graphics = struct {
    pub const Color = packed struct(u32) {
        /// The transparency component.
        /// Note that the value is reversed from the alpha component, meaning `0xff` is fully transparent.
        b: u8,
        g: u8,
        r: u8,
        t: u8,

        pub const black = Color{ .r = 0x00, .g = 0x00, .b = 0x00, .t = 0x00 };
        pub const white = Color{ .r = 0xff, .g = 0xff, .b = 0xff, .t = 0x00 };
        pub const red = Color{ .r = 0xff, .g = 0x00, .b = 0x00, .t = 0x00 };
        pub const blue = Color{ .r = 0x00, .g = 0xff, .b = 0x00, .t = 0x00 };
        pub const green = Color{ .r = 0x00, .g = 0x00, .b = 0xff, .t = 0x00 };

        pub fn fromVector4(v: Vector4) Color {
            return .{
                .r = @intFromFloat(v.x * 255.0),
                .g = @intFromFloat(v.y * 255.0),
                .b = @intFromFloat(v.z * 255.0),
                .t = @intFromFloat((1.0 - v.w) * 255.0),
            };
        }

        pub fn toVector4(c: Color) Vector4 {
            return .{
                .x = @as(f32, @floatFromInt(c.r)) / 255.0,
                .y = @as(f32, @floatFromInt(c.g)) / 255.0,
                .z = @as(f32, @floatFromInt(c.b)) / 255.0,
                .w = @as(f32, @floatFromInt(255 - c.t)) / 255.0,
            };
        }
    };

    mlx_ptr: ?*anyopaque,
    win_ptr: ?*anyopaque,

    // The MiniLibX image used as a buffer.
    canvas: ?*mlx.t_img,

    width: usize,
    height: usize,

    allocator: Allocator,

    color_buffer: []Color,
    /// Allocated using `allocator`.
    depth_buffer: []f32,

    clear_color: Color,

    model: Matrix4,
    view: Matrix4,
    projection: Matrix4,
    /// The Model-View-Projection matrix.
    mvp: Matrix4,

    render_mode: Settings.RenderMode = .texture,

    pub fn init(
        mlx_ptr: ?*anyopaque,
        win_ptr: ?*anyopaque,
        w: usize,
        h: usize,
        allocator: Allocator,
    ) !Graphics {
        const img: ?*mlx.t_img = @ptrCast(@alignCast(mlx.mlx_new_image(mlx_ptr, @intCast(w), @intCast(h))));

        return Graphics{
            .mlx_ptr = mlx_ptr,
            .win_ptr = win_ptr,
            .canvas = img,
            .width = w,
            .height = h,
            .allocator = std.heap.page_allocator,
            .color_buffer = @as([*]Color, @ptrCast(@alignCast(img.?.data)))[0..@as(usize, @intCast(w * h))],
            .depth_buffer = try allocator.alloc(f32, @as(usize, @intCast(w * h))),
            .clear_color = Color.black,
            .model = Matrix4.identity(),
            .view = Matrix4.identity(),
            .projection = Matrix4.identity(),
            .mvp = Matrix4.identity(),
        };
    }

    pub fn resize(self: *Graphics, w: i32, h: i32) !void {
        _ = self;
        _ = w;
        _ = h;

        // TODO: recreate canvas, reallocate depth_buffer, ...
    }

    pub fn present(self: *const Graphics) void {
        _ = mlx.mlx_put_image_to_window(self.mlx_ptr, self.win_ptr, self.canvas, 0, 0);
    }

    pub fn clear(self: *Graphics) void {
        for (0..@as(usize, @intCast(self.width * self.height))) |i| {
            self.color_buffer[i] = self.clear_color;
            // FIXME: I'm 100% sure this should be std.math.inf(f32) instead of 1.0
            self.depth_buffer[i] = 1.0;
        }
    }

    fn recalculateMVP(self: *Graphics) void {
        self.mvp = self.projection.mulMat4(self.view).mulMat4(self.model);
    }

    pub fn loadModelMatrix(self: *Graphics, m: Matrix4) void {
        self.model = m;
        // self.recalculateMVP();
    }

    pub fn loadViewMatrix(self: *Graphics, m: Matrix4) void {
        self.view = m;
        // self.recalculateMVP();
    }

    pub fn loadProjectionMatrix(self: *Graphics, m: Matrix4) void {
        self.projection = m;
        // self.recalculateMVP();
    }

    inline fn edgeFn(a: Vector3, b: Vector3, c: Vector3) f32 {
        return (a.x - c.x) * (b.y - c.y) - (a.y - c.y) * (b.x - c.x);
    }

    // Two steps are necessary to correctly interpolate a value:
    // - Divide every values by their associated z vertex component.
    // - Compute the interpolate value.

    inline fn preInterpolateVector3(v0: *Vector3, v1: *Vector3, v2: *Vector3, z0: f32, z1: f32, z2: f32) void {
        v0.x /= z0;
        v0.y /= z0;
        v1.x /= z1;
        v1.y /= z1;
        v2.x /= z2;
        v2.y /= z2;
    }

    inline fn interpolateVector3(v0: Vector3, v1: Vector3, v2: Vector3, w: Vector3, z: f32) Vector3 {
        return Vector3{
            .x = (w.x * v0.x + w.y * v1.x + w.z * v2.x) * z,
            .y = (w.x * v0.y + w.y * v1.y + w.z * v2.y) * z,
            .z = (w.x * v0.z + w.y * v1.z + w.z * v2.z) * z,
        };
    }

    inline fn preInterpolateVector2(v0: *Vector2, v1: *Vector2, v2: *Vector2, z0: f32, z1: f32, z2: f32) void {
        v0.x /= z0;
        v0.y /= z0;
        v1.x /= z1;
        v1.y /= z1;
        v2.x /= z2;
        v2.y /= z2;
    }

    inline fn interpolateVector2(v0: Vector2, v1: Vector2, v2: Vector2, w: Vector3, z: f32) Vector2 {
        return Vector2{
            .x = (w.x * v0.x + w.y * v1.x + w.z * v2.x) * z,
            .y = (w.x * v0.y + w.y * v1.y + w.z * v2.y) * z,
        };
    }

    inline fn preInterpolateScalar(v0: *f32, v1: *f32, v2: *f32, z0: f32, z1: f32, z2: f32) void {
        v0.* /= z0;
        v1.* /= z1;
        v2.* /= z2;
    }

    inline fn interpolateScalar(v0: Vector3, v1: Vector3, v2: Vector3, w: Vector3, z: f32) Vector3 {
        return (w.x * v0.x + w.y * v1.x + w.z * v2.x) * z;
    }

    pub const DrawOptions = struct {
        texture: ?Texture = null,
        position: Vector3 = .{},
        rotation: Vector3 = .{},
        offset: Vector3 = .{},
    };

    pub fn draw(self: *const Graphics, mesh: *const Mesh, options: DrawOptions) void {
        const width: f32 = @floatFromInt(self.width);
        const height: f32 = @floatFromInt(self.height);

        // const off = Vector3{
        //     .y = options.offset.y,
        //     .z = options.offset.z,
        // };
        // const model = Matrix4.modelWithOffset(options.position, options.rotation, off);
        const model = Matrix4.model(options.position, options.rotation);
        const mvp = self.projection.mul(self.view).mul(model);

        for (mesh.faces.items, 0..mesh.faces.items.len) |face, face_index| {
            var v0 = mesh.vertices.items[face.vertices[0]];
            var v1 = mesh.vertices.items[face.vertices[1]];
            var v2 = mesh.vertices.items[face.vertices[2]];

            // TODO: compute normals if not present.
            // TODO: compute texture coords if not present.

            v0 = mvp.mul(v0);
            v1 = mvp.mul(v1);
            v2 = mvp.mul(v2);

            const edge1 = v1.sub(v0).normalized();
            const edge2 = v2.sub(v1).normalized();
            const face_normal = edge1.cross(edge2);

            // Only draw front faces.
            if (face_normal.dot(Vector3{ .z = 1 }) < 0.0) {
                continue;
            }

            var n0 = mesh.normals.items[face.normals[0]];
            var n1 = mesh.normals.items[face.normals[1]];
            var n2 = mesh.normals.items[face.normals[2]];

            var t0: Vector2 = undefined;
            var t1: Vector2 = undefined;
            var t2: Vector2 = undefined;

            if (mesh.textureCoords.items.len > 1) {
                t0 = mesh.textureCoords.items[face.textures[0]];
                t1 = mesh.textureCoords.items[face.textures[1]];
                t2 = mesh.textureCoords.items[face.textures[2]];
            } else {
                const pv0 = mesh.vertices.items[face.vertices[0]];
                const pv1 = mesh.vertices.items[face.vertices[1]];
                const pv2 = mesh.vertices.items[face.vertices[2]];

                if (face_normal.dot(Vector3.z_axis) >= 0.0 or face_normal.dot(Vector3.inv_z_axis) >= 0.0) {
                    t0 = pv0.yz();
                    t1 = pv1.yz();
                    t2 = pv2.yz();
                } else {
                    t0 = pv0.xy();
                    t1 = pv1.xy();
                    t2 = pv2.xy();
                }
            }

            n0 = self.model.mul(n0);
            n1 = self.model.mul(n1);
            n2 = self.model.mul(n2);

            // FIXME:
            // This fix the depth buffer bug. There is still a performance hit when the camera enters a mesh.
            if (v0.z < 0.1 or v1.z < 0.1 or v2.z < 0.1) {
                continue;
            }

            // Convert from screen space to NDC then raster (in one go)
            v0.x = (1 + v0.x) * 0.5 * width;
            v0.y = (1 + v0.y) * 0.5 * height;

            v1.x = (1 + v1.x) * 0.5 * width;
            v1.y = (1 + v1.y) * 0.5 * height;

            v2.x = (1 + v2.x) * 0.5 * width;
            v2.y = (1 + v2.y) * 0.5 * height;

            var min_x: isize = @intFromFloat(@min(v0.x, v1.x, v2.x));
            var max_x: isize = @intFromFloat(@max(v0.x, v1.x, v2.x));
            var min_y: isize = @intFromFloat(@min(v0.y, v1.y, v2.y));
            var max_y: isize = @intFromFloat(@max(v0.y, v1.y, v2.y));

            // The triangle is outside of the screen.
            if (min_x >= self.width or min_y >= self.height or max_x < 0 or max_y < 0) {
                continue;
            }

            min_x = @max(min_x, 0);
            min_y = @max(min_y, 0);
            max_x = @min(max_x, @as(isize, @intCast(self.width)) - 1);
            max_y = @min(max_y, @as(isize, @intCast(self.height)) - 1);

            preInterpolateVector2(&t0, &t1, &t2, v0.z, v1.z, v2.z);
            preInterpolateVector3(&n0, &n1, &n2, v0.z, v1.z, v2.z);

            // inverse the z-axis
            v0.z = 1.0 / v0.z;
            v1.z = 1.0 / v1.z;
            v2.z = 1.0 / v2.z;

            const area = edgeFn(v0, v1, v2);

            for (@intCast(min_y)..@intCast(max_y + 1)) |y| {
                for (@intCast(min_x)..@intCast(max_x + 1)) |x| {
                    const p = Vector3{
                        .x = @as(f32, @floatFromInt(x)) + 0.5,
                        .y = @as(f32, @floatFromInt(y)) + 0.5,
                        .z = 0.0,
                    };
                    var w0 = edgeFn(v1, v2, p);
                    var w1 = edgeFn(v2, v0, p);
                    var w2 = edgeFn(v0, v1, p);

                    if (w0 < 0.0 or w1 < 0.0 or w2 < 0.0) {
                        continue;
                    }

                    w0 /= area;
                    w1 /= area;
                    w2 /= area;

                    const z = w0 * v0.z + w1 * v1.z + w2 * v2.z;
                    const inv_z = 1.0 / z;
                    const w = Vector3{ .x = w0, .y = w1, .z = w2 };

                    const uv = interpolateVector2(t0, t1, t2, w, inv_z);
                    const n = interpolateVector3(n0, n1, n2, w, inv_z);

                    const index: usize = x + (self.height - y - 1) * self.width;
                    const rev_z = 1.0 - z;

                    if (rev_z > self.depth_buffer[index]) {
                        continue;
                    }

                    self.color_buffer[index] = fragmentShader(self.render_mode, uv, n, options.texture, face_index);
                    self.depth_buffer[index] = rev_z;
                }
            }
        }
    }

    const colors: [7]Color = .{
        Color.gray(30),
        Color.gray(54),
        Color.gray(70),
        Color.gray(84),
        Color.gray(102),
        Color.gray(127),
        Color.gray(140),
    };

    inline fn fragmentShader(
        mode: Settings.RenderMode,
        uv: Vector2,
        normal: Vector3,
        texture: ?Texture,
        index: usize,
    ) Color {
        const color = switch (mode) {
            .texture => if (texture) |t|
                t.sample(uv, .{ .repeat = true })
            else
                fragmentShader(.color, uv, normal, texture, index),
            .color => a: {
                break :a colors[index % colors.len];
            },
        };

        return color;
    }
};
