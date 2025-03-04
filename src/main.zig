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
var texture: ?Texture = null;

const window_width: i32 = 1280;
const window_height: i32 = 720;

var rotation_y: f32 = 0.0;

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;

const Settings = struct {
    enable_rotation: bool = true,
    render_mode: Graphics.Mode = .texture,
    rotation_speed: f32 = 0.01,
    model_x: f32 = 0.0,
    model_y: f32 = 1.0,
    model_z: f32 = -4.0,
    fov: f32 = 60.0,
    move_speed: f32 = 0.2,
};

var settings: Settings = .{};

var last_update: i64 = 0;
const time_between_frame = 1_000_000 / 60;

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
    const texture_filename = args.next();

    mesh = Mesh.loadFromFile(mesh_filename, allocator) catch {
        std.log.err("unable to open mesh file: {s}", .{mesh_filename});
        return;
    };
    defer mesh.deinit();

    if (texture_filename) |texture_filename2| {
        texture = Texture.loadFromFile(texture_filename2, allocator) catch {
            std.log.err("unable to open texture file: {s}", .{texture_filename2});
            return;
        };
    }
    defer if (texture) |t| t.deinit();

    const mlx_ptr = mlx.mlx_init() orelse std.debug.panic("unable to initialize mlx", .{});
    defer _ = mlx.mlx_destroy_display(mlx_ptr);

    const win_ptr = mlx.mlx_new_window(mlx_ptr, window_width, window_height, @ptrCast(@constCast("scop"))) orelse std.debug.panic("unable to create the window", .{});
    defer _ = mlx.mlx_destroy_window(mlx_ptr, win_ptr);

    const stderr = std.io.getStdOut().writer();
    nosuspend try stderr.print(
        \\
        \\F1           - Toggle rendering mode
        \\Space        - Toggle rotation
        \\Up / Down    - Move the object on the Y axis
        \\Left / Right - Move the object on the X axis
        \\Shift / Ctrl - Move the object on the Z axis
        \\
        \\
    , .{});

    gfx = Graphics.init(mlx_ptr, win_ptr, window_width, window_height, allocator) catch std.debug.panic("unable to enable graphics", .{});
    gfx.render_mode = settings.render_mode;

    const view = Matrix4.translation(.{ .x = 0.0, .y = 0.0, .z = 0.0 });
    const proj = Matrix4.projection(settings.fov, window_width, window_height, 0.001, 1000.0);

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
    gfx.draw(&mesh, .{
        .texture = texture,
        .position = .{ .x = settings.model_x, .y = settings.model_y, .z = settings.model_z },
        .rotation = .{ .y = rotation_y },
        .offset = mesh.getMiddlePoint(),
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
