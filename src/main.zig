const std = @import("std");
const mlx = @import("mlx");
const argzon = @import("argzon");
const math = @import("math.zig");

const SoftwareRenderer = @import("SoftwareRenderer.zig");
const OpenGLRenderer = @import("OpenGLRenderer.zig");

const Mesh = @import("Mesh.zig");
const Texture = @import("Texture.zig");
const Vector3 = math.Vector3;
const Matrix4 = math.Matrix4;
const Settings = @import("Settings.zig");

var gpa: std.heap.DebugAllocator(.{}) = .init;

// TODO: extract into `cli.zon` after:
// https://github.com/ziglang/zig/pull/22907
const @"import(cli.zon)" = .{
    .name = .scop,
    .description = "3D model viewer",
    .options = .{
        .{
            .short = 'r',
            .long = "renderer",
            .type = "?string",
            .description = "Select a renderer (opengl, software)",
        },
        .{
            .short = 'c',
            .long = "config",
            .type = "?string",
            .description = "Use a different configuration file",
        },
    },
    .flags = .{
        // .{
        //     .short = 'r',
        //     .long = "raw",
        //     .description = "Output raw values (otherwise, ZON).",
        // },
    },
    .positionals = .{
        .{
            .meta = .model,
            .type = "string",
            .description = "Model",
        },
        .{
            .meta = .texture,
            .type = "string",
            .default = "",
            .description = "Texture",
        },
    },
};

pub fn main() !void {
    const allocator = gpa.allocator();

    const Args = argzon.Args(@"import(cli.zon)", &.{});
    const args = try Args.parse(allocator, std.io.getStdErr().writer(), .{});

    // const query = args.positionals.model;

    // Read the configuration file
    const f: ?std.fs.File = std.fs.cwd().openFile(args.options.config orelse "settings.zon", .{}) catch null;
    var settings: Settings = undefined;
    if (f) |file| read_settings: {
        defer file.close();
        const buffer = file.readToEndAllocOptions(allocator, 100_000, null, 8, 0) catch {
            break :read_settings;
        };
        settings = std.zon.parse.fromSlice(Settings, allocator, buffer, null, .{}) catch {
            break :read_settings;
        };
    }

    const renderer_name = args.options.renderer orelse "software";
    const model_path = args.positionals.model;
    const texture_path: ?[]const u8 = if (args.positionals.texture.len > 0)
        args.positionals.texture
    else
        null;

    const model = Mesh.loadFromFile(model_path, allocator) catch {
        std.log.err("invalid mesh file: {s}", .{model_path});
        return;
    };

    const texture = if (texture_path) |path|
        Texture.loadFromFile(path, allocator) catch {
            std.log.err("invalid tetxure file: {s}", .{model_path});
            return;
        }
    else
        null;

    const stderr = std.io.getStdOut().writer();
    nosuspend try stderr.print(
        \\
        \\F1           - Toggle rendering mode
        \\F2           - Toggle lighting
        \\Space        - Toggle rotation
        \\Up / Down    - Move the object on the Y axis
        \\Left / Right - Move the object on the X axis
        \\Shift / Ctrl - Move the object on the Z axis
        \\
        \\
    , .{});

    if (std.mem.eql(u8, renderer_name, "software")) {
        const renderer = SoftwareRenderer.init(allocator, settings, model, texture);
        try renderer.run();
    } else if (std.mem.eql(u8, renderer_name, "opengl")) {
        const renderer = OpenGLRenderer.init(allocator, settings, model, texture);
        try renderer.run();
    } else {
        std.log.err("invalid renderer: {s}", .{renderer_name});
    }
}
