const std = @import("std");
const mlx = @import("mlx");
const math = @import("math.zig");

const Graphics = @import("Graphics.zig");
const Mesh = @import("Mesh.zig");
const Texture = @import("Texture.zig");
const Vector3 = math.Vector3;
const Matrix4 = math.Matrix4;

var gfx: Graphics = undefined;
var mesh: Mesh = undefined;
var texture: Texture = undefined;

const window_width: i32 = 1280;
const window_height: i32 = 720;

var rotation_y: f32 = 0.0;

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;

const Settings = struct {
    rotation_speed: f32 = 0.01,
    model_y: f32 = 1.0,
    model_z: f32 = -4.0,
};

var settings: Settings = .{};
var rotation_enabled: bool = true;

pub fn main() !void {
    const allocator = gpa.allocator();

    // Read the configuration file
    const f: ?std.fs.File = std.fs.cwd().openFile("settings.zon", .{}) catch null;
    if (f) |file| read_settings: {
        defer file.close();
        const buffer = file.readToEndAllocOptions(allocator, 100_000, null, 8, 0) catch {
            break :read_settings;
        };
        settings = std.zon.parse.fromSlice(Settings, allocator, buffer, null, .{}) catch {
            break :read_settings;
        };
    }

    // Read program arguments
    var args = std.process.args();
    _ = args.next();

    const mesh_filename = args.next() orelse {
        std.log.err("missing mesh file", .{});
        return;
    };
    const texture_filename = args.next() orelse {
        std.log.err("missing texture file", .{});
        return;
    };

    mesh = Mesh.loadFromFile(mesh_filename, allocator) catch {
        std.log.err("unable to open mesh file: {s}", .{mesh_filename});
        return;
    };
    texture = Texture.loadFromFile(texture_filename, allocator) catch {
        std.log.err("unable to open texture file: {s}", .{mesh_filename});
        return;
    };

    const mlx_ptr = mlx.mlx_init() orelse std.debug.panic("unable to initialize mlx", .{});
    defer _ = mlx.mlx_destroy_display(mlx_ptr);

    const win_ptr = mlx.mlx_new_window(mlx_ptr, window_width, window_height, @ptrCast(@constCast("scop"))) orelse std.debug.panic("unable to create the window", .{});
    defer _ = mlx.mlx_destroy_window(mlx_ptr, win_ptr);

    const stderr = std.io.getStdOut().writer();
    nosuspend try stderr.print(
        \\
        \\F1 - Enable textured rendering
        \\F2 - Enable colored rendering
        \\F3 - Toggle rotation
        \\
    , .{});

    gfx = Graphics.init(mlx_ptr, win_ptr, window_width, window_height) catch std.debug.panic("unable to enable graphics", .{});

    const view = Matrix4.translation(.{ .x = 0.0, .y = 0.0, .z = 0.0 });
    const proj = Matrix4.projection(70.0, window_width, window_height, 0.01, 1000.0);

    gfx.loadViewMatrix(view);
    gfx.loadProjectionMatrix(proj);

    _ = mlx.mlx_hook(win_ptr, mlx.DestroyNotify, 0, @ptrCast(&onDestroyNotify), null);
    _ = mlx.mlx_hook(win_ptr, mlx.KeyPress, mlx.KeyPressMask, @ptrCast(&onKeyPress), null);
    _ = mlx.mlx_loop_hook(mlx_ptr, @ptrCast(&tick), null);
    _ = mlx.mlx_loop(mlx_ptr);
}

fn tick(_: ?*anyopaque) callconv(.c) void {
    const model = Matrix4.model(.{ .x = 0.0, .y = settings.model_y, .z = settings.model_z }, .{ .x = 0.0, .y = rotation_y, .z = 0.0 });
    gfx.loadModelMatrix(model);

    gfx.clear();
    gfx.draw(&mesh, &texture);
    gfx.present();

    if (rotation_enabled) {
        rotation_y += settings.rotation_speed;
    }
}

fn onDestroyNotify(_: ?*anyopaque) callconv(.c) void {
    _ = mlx.mlx_loop_end(gfx.mlx_ptr);
}

fn onKeyPress(keycode: c_int, _: ?*anyopaque) callconv(.c) void {
    if (keycode == mlx.XK_F1) {
        gfx.render_mode = .texture;
    } else if (keycode == mlx.XK_F2) {
        gfx.render_mode = .color;
    } else if (keycode == mlx.XK_F3) {
        rotation_enabled = !rotation_enabled;
    }
}
