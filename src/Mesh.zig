const std = @import("std");
const math = @import("math.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vector2 = math.Vector2;
const Vector3 = math.Vector3;

const Mesh = @This();

pub const Face = struct {
    vertices: [3]u32,
    textures: [3]u32,
    normals: [3]u32,
};

vertices: ArrayList(Vector3),
textureCoords: ArrayList(Vector2),
normals: ArrayList(Vector3),
faces: ArrayList(Face),

allocator: Allocator,

fn readFace2(nums: []const []const u8) !Face {
    var face: Face = undefined;

    for (nums, 0..3) |s, index| {
        var slashIter = std.mem.splitAny(u8, s, "/");
        const sv = slashIter.next() orelse return error.InvalidLine; // minimum required (vertex index).
        const svt = slashIter.next();
        const svn = slashIter.next();

        // Indices start at 1 in .obj files.
        face.vertices[index] = try std.fmt.parseInt(u32, sv, 10) - 1;

        // TODO: setting value to 0 if not found is not ideal as it required `textureCoords` and `normals` to hold one dummy
        // element if empty.

        if (svt) |vt| {
            face.textures[index] = try std.fmt.parseInt(u32, vt, 10) - 1;
        } else {
            face.textures[index] = 0;
        }

        if (svn) |vn| {
            face.normals[index] = try std.fmt.parseInt(u32, vn, 10) - 1;
        } else {
            face.normals[index] = 0;
        }
    }

    return face;
}

fn readFace(buf: []const u8, faces: *ArrayList(Face)) !void {
    var splitIter = std.mem.splitAny(u8, buf, " ");
    const s0 = splitIter.next() orelse return error.InvalidLine;
    const s1 = splitIter.next() orelse return error.InvalidLine;
    const s2 = splitIter.next() orelse return error.InvalidLine;

    if (splitIter.next()) |s3| {
        try faces.append(try readFace2(&[3][]const u8{ s0, s1, s2 }));
        try faces.append(try readFace2(&[3][]const u8{ s0, s2, s3 }));
    } else {
        try faces.append(try readFace2(&[3][]const u8{ s0, s1, s2 }));
    }
}

// TODO: Check for out of bounds.

pub fn loadFromFile(path: []const u8, gpa: Allocator) !Mesh {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const reader = file.reader();

    var vertices = ArrayList(Vector3).init(gpa);
    var textureCoords = ArrayList(Vector2).init(gpa);
    var normals = ArrayList(Vector3).init(gpa);
    var faces = ArrayList(Face).init(gpa);

    errdefer vertices.deinit();
    errdefer textureCoords.deinit();
    errdefer normals.deinit();
    errdefer faces.deinit();

    while (try reader.readUntilDelimiterOrEofAlloc(gpa, '\n', 8192)) |line| {
        defer gpa.free(line);

        if (line.len >= 1 and line[0] == '#') {
            continue;
        }

        if (line.len >= 2 and std.mem.eql(u8, line[0..2], "v ")) {
            var iter = std.mem.splitAny(u8, line[2..], " ");
            const x = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);
            const y = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);
            const z = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);

            try vertices.append(Vector3{ .x = x, .y = y, .z = z });
        } else if (line.len >= 3 and std.mem.eql(u8, line[0..3], "vn ")) {
            var iter = std.mem.splitAny(u8, line[3..], " ");
            const x = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);
            const y = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);
            const z = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);

            try normals.append(Vector3{ .x = x, .y = y, .z = z });
        } else if (line.len >= 3 and std.mem.eql(u8, line[0..3], "vt ")) {
            var iter = std.mem.splitAny(u8, line[3..], " ");
            const x = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);
            const y = try std.fmt.parseFloat(f32, iter.next() orelse return error.InvalidLine);

            try textureCoords.append(Vector2{ .x = x, .y = y });
        } else if (line.len >= 2 and std.mem.eql(u8, line[0..2], "f ")) {
            // format is `f 0/0/0 1/1/1 2/2/2`
            try readFace(line[2..], &faces);
        }
    }

    if (textureCoords.items.len == 0) {
        try textureCoords.append(Vector2{});
    }

    if (normals.items.len == 0) {
        try normals.append(Vector3{});
    }

    return Mesh{
        .vertices = vertices,
        .textureCoords = textureCoords,
        .normals = normals,
        .faces = faces,
        .allocator = gpa,
    };
}

pub fn deinit(self: *const Mesh) void {
    self.vertices.deinit();
    self.textureCoords.deinit();
    self.normals.deinit();
    self.faces.deinit();
}
