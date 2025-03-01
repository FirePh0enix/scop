const std = @import("std");
const mlx = @import("mlx");
const math = @import("math.zig");

const Graphics = @import("Graphics.zig");
const Mesh = @import("Mesh.zig");
const Vector3 = math.Vector3;
const Matrix4 = math.Matrix4;

var gfx: Graphics = undefined;
var teapot: Mesh = undefined;

const window_width: i32 = 1280;
const window_height: i32 = 720;

var rotation_y: f32 = 0.0;

pub fn main() !void {
    const mlx_ptr = mlx.mlx_init() orelse std.debug.panic("unable to initialize mlx", .{});
    defer _ = mlx.mlx_destroy_display(mlx_ptr);

    const win_ptr = mlx.mlx_new_window(mlx_ptr, window_width, window_height, @ptrCast(@constCast("scop"))) orelse std.debug.panic("unable to create the window", .{});
    defer _ = mlx.mlx_destroy_window(mlx_ptr, win_ptr);

    gfx = Graphics.init(mlx_ptr, win_ptr, window_width, window_height) catch std.debug.panic("unable to enable graphics", .{});

    teapot = try Mesh.load("models/teapot.obj", std.heap.page_allocator);
    defer teapot.deinit();

    const view = Matrix4.translation(.{ .x = 0.0, .y = 0.0, .z = 0.0 });
    const proj = Matrix4.projection(70.0, window_width, window_height, 0.01, 1000.0);

    gfx.loadViewMatrix(view);
    gfx.loadProjectionMatrix(proj);

    _ = mlx.mlx_hook(win_ptr, mlx.DestroyNotify, 0, @ptrCast(&onDestroyNotify), null);
    _ = mlx.mlx_loop_hook(mlx_ptr, @ptrCast(&tick), null);
    _ = mlx.mlx_loop(mlx_ptr);
}

fn tick(_: ?*anyopaque) callconv(.c) void {
    const model = Matrix4.model(.{ .x = 0.0, .y = -2.0, .z = -17.0 }, .{ .x = 0.0, .y = rotation_y, .z = 0.0 });
    gfx.loadModelMatrix(model);

    gfx.clear();
    gfx.draw(&teapot);
    gfx.present();

    rotation_y += 0.01;
}

fn onDestroyNotify(_: ?*anyopaque) callconv(.c) void {
    _ = mlx.mlx_loop_end(gfx.mlx_ptr);
}
