const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Vector2 = @import("math.zig").Vector2;
const Graphics = @import("Graphics.zig");
const Texture = @This();
const Color = Graphics.Color;

buffer: ArrayList(Color),
width: usize,
height: usize,
allocator: Allocator,

const Tga = packed struct {
    magic: u8,
    colormap: u8,
    encoding: u8,
    cmaporig: u16,
    cmaplen: u16,
    cmapent: u8,
    x: u16,
    y: u16,
    w: u16,
    h: u16,
    bpp: u8,
    pixel_type: u8,
};

// const ExtensionArea = packed struct {
//     size: u16,
//     author_name: [41:0]u8,
//     author_comment: [324:0]u8,
// };

const max_file_size: usize = 100_000_000;

fn readNoMap32(tga: *const Tga, buf: []const u8, gpa: Allocator) !ArrayList(Color) {
    const size = @as(usize, @intCast(tga.w)) * @as(usize, @intCast(tga.h));
    var i: usize = 0;
    var pixels = try ArrayList(Color).initCapacity(gpa, size);

    while (i < size * 4) {
        var color: Color = @bitCast([4]u8{ buf[i], buf[i + 1], buf[i + 2], buf[i + 3] });
        color.t = 255 - color.t;
        try pixels.append(color);
        i += 4;
    }

    return pixels;
}

fn readNoMap24(tga: *const Tga, buf: []const u8, gpa: Allocator) !ArrayList(Color) {
    var i: usize = 0;
    var pixels = ArrayList(Color).init(gpa);

    while (i < @as(usize, @intCast(tga.w)) * @as(usize, @intCast(tga.h))) {
        try pixels.append(Color{
            .b = buf[i],
            .g = buf[i + 1],
            .r = buf[i + 2],
            .t = 0,
        });
        i += 3;
    }

    return pixels;
}

fn readMap32(tga: *const Tga, buf: []const u8, gpa: Allocator) !ArrayList(Color) {
    var i: usize = 0;
    var pixels = ArrayList(Color).init(gpa);

    const pixels_buffer = buf[(@as(usize, @intCast(tga.cmapent)) >> 3) * @as(usize, @intCast(tga.cmaplen)) ..];

    while (i < @as(usize, @intCast(tga.w)) * @as(usize, @intCast(tga.h))) {
        try pixels.append(Color{
            .b = pixels_buffer[buf[i]],
            .g = pixels_buffer[buf[i] + 1],
            .r = pixels_buffer[buf[i] + 2],
            .t = pixels_buffer[buf[i] + 3],
        });
        i += 1;
    }

    return pixels;
}

fn readMap24(tga: *const Tga, buf: []const u8, gpa: Allocator) !ArrayList(Color) {
    var i: usize = 0;
    var pixels = ArrayList(Color).init(gpa);

    const pixels_buffer = buf[(@as(usize, @intCast(tga.cmapent)) >> 3) * @as(usize, @intCast(tga.cmaplen)) ..];

    while (i < @as(usize, @intCast(tga.w)) * @as(usize, @intCast(tga.h))) {
        try pixels.append(Color{
            .b = pixels_buffer[buf[i]],
            .g = pixels_buffer[buf[i] + 1],
            .r = pixels_buffer[buf[i] + 2],
            .t = 0,
        });
        i += 1;
    }

    return pixels;
}

fn readGray8(tga: *const Tga, buf: []const u8, gpa: Allocator) !ArrayList(Color) {
    var i: usize = 0;
    var pixels = ArrayList(Color).init(gpa);

    while (i < @as(usize, @intCast(tga.w)) * @as(usize, @intCast(tga.h))) {
        try pixels.append(Color{
            .b = buf[i],
            .g = buf[i],
            .r = buf[i],
            .t = 0,
        });
        i += 1;
    }

    return pixels;
}

pub fn loadFromFile(
    path: []const u8,
    allocator: Allocator,
) !Texture {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, max_file_size);
    defer allocator.free(buffer);

    var tga: Tga = undefined;
    @memcpy(@as([*]u8, @ptrCast(&tga)), buffer[0..@sizeOf(Tga)]);
    const tga_data = buffer[18..]; // FIXME: The header size should be 18 but is 32 for some reason, causing OOB when indexing the buffer

    const pixels = if (tga.bpp == 32 and tga.colormap == 0)
        readNoMap32(&tga, tga_data, allocator)
    else if (tga.bpp == 24 and tga.colormap == 0)
        readNoMap24(&tga, tga_data, allocator)
    else if (tga.bpp == 8 and tga.colormap == 1 and tga.cmapent == 32)
        readMap32(&tga, tga_data, allocator)
    else if (tga.bpp == 8 and tga.colormap == 1 and tga.cmapent == 24)
        readMap24(&tga, tga_data, allocator)
    else if (tga.bpp == 8 and tga.colormap == 0)
        readGray8(&tga, tga_data, allocator)
    else {
        std.debug.print("bpp = {}\n", .{tga.bpp});
        return error.InvalidFormat;
    };

    return Texture{
        .buffer = try pixels,
        .allocator = allocator,
        .width = @intCast(tga.w),
        .height = @intCast(tga.h),
    };
}

pub fn deinit(self: *const Texture) void {
    self.buffer.deinit();
}

pub inline fn sample(self: *const Texture, uv: Vector2) Color {
    @setRuntimeSafety(false);

    const x: usize = std.math.clamp(@as(usize, @intFromFloat(uv.x * @as(f32, @floatFromInt(self.width - 1)))), 0, self.width - 1);
    const y: usize = std.math.clamp(self.height - 1 - @as(usize, @intFromFloat(uv.y * @as(f32, @floatFromInt(self.height - 1)))), 0, self.height - 1);

    return self.buffer.items[x + y * self.width];
}
