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

fn readFace2(
    nums: []const []const u8,
    num_vertex: usize,
    num_normal: usize,
    num_textures: usize,
) !Face {
    var face: Face = undefined;

    for (nums, 0..3) |s, index| {
        var slashIter = std.mem.splitAny(u8, s, "/");
        const sv = slashIter.next() orelse return error.InvalidLine; // minimum required (vertex index).
        const svt = slashIter.next();
        const svn = slashIter.next();

        // Indices start at 1 in .obj files.
        face.vertices[index] = try std.fmt.parseInt(u32, sv, 10) - 1;
        if (face.vertices[index] > num_vertex) return error.InvalidVertexId;

        // TODO: setting value to 0 if not found is not ideal as it required `textureCoords` and `normals` to hold one dummy
        // element if empty.

        if (svt) |vt| {
            face.textures[index] = try std.fmt.parseInt(u32, vt, 10) - 1;
            if (face.textures[index] > num_textures) return error.InvalidTextureCoordsId;
        } else {
            face.textures[index] = 0;
        }

        if (svn) |vn| {
            face.normals[index] = try std.fmt.parseInt(u32, vn, 10) - 1;
            if (face.normals[index] > num_normal) return error.InvalidNormalId;
        } else {
            face.normals[index] = 0;
        }
    }

    return face;
}

fn readFace(
    buf: []const u8,
    faces: *ArrayList(Face),
    num_vertex: usize,
    num_normal: usize,
    num_textures: usize,
) !void {
    var splitIter = std.mem.splitAny(u8, buf, " ");
    const s0 = splitIter.next() orelse return error.InvalidLine;
    const s1 = splitIter.next() orelse return error.InvalidLine;
    const s2 = splitIter.next() orelse return error.InvalidLine;

    if (splitIter.next()) |s3| {
        try faces.append(try readFace2(&[3][]const u8{ s0, s1, s2 }, num_vertex, num_normal, num_textures));
        try faces.append(try readFace2(&[3][]const u8{ s0, s2, s3 }, num_vertex, num_normal, num_textures));
    } else {
        try faces.append(try readFace2(&[3][]const u8{ s0, s1, s2 }, num_vertex, num_normal, num_textures));
    }
}

// TODO: Check for out of bounds.

pub fn loadFromFile(path: []const u8, gpa: Allocator) !Mesh {
    const file = try std.fs.cwd().openFile(path, .{});
    const file_data = try file.readToEndAlloc(gpa, 800_000_000);
    defer gpa.free(file_data);

    // Reading line by line is a bottleneck for large files! It's better to read the whole file then reading
    // each lines, but it will take more memory.

    file.close();

    var vertices = ArrayList(Vector3).init(gpa);
    var textureCoords = ArrayList(Vector2).init(gpa);
    var normals = ArrayList(Vector3).init(gpa);
    var faces = ArrayList(Face).init(gpa);

    errdefer vertices.deinit();
    errdefer textureCoords.deinit();
    errdefer normals.deinit();
    errdefer faces.deinit();

    var line_iter = std.mem.splitSequence(u8, file_data, "\n");

    while (line_iter.next()) |line| {
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
            try readFace(line[2..], &faces, vertices.items.len, normals.items.len, textureCoords.items.len);
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

pub const Box = struct {
    min: Vector3,
    max: Vector3,
};

pub fn getBounds(self: *const Mesh) Box {
    if (self.vertices.items.len == 0) {
        return .{ .min = .{}, .max = .{} };
    }

    var min = self.vertices.items[0];
    var max = self.vertices.items[0];

    for (self.vertices.items) |vertex| {
        if (vertex.x < min.x) {
            min.x = vertex.x;
        }
        if (vertex.x > max.x) {
            max.x = vertex.x;
        }

        if (vertex.y < min.y) {
            min.y = vertex.y;
        }
        if (vertex.y > max.y) {
            max.y = vertex.y;
        }

        if (vertex.z < min.z) {
            min.z = vertex.z;
        }
        if (vertex.z > max.z) {
            max.z = vertex.z;
        }
    }

    return Box{ .min = min, .max = max };
}

pub fn getMiddlePoint(self: *const Mesh) Vector3 {
    const bounds = self.getBounds();
    return bounds.max.sub(bounds.min).scale(0.5);
}

pub fn deinit(self: *const Mesh) void {
    self.vertices.deinit();
    self.textureCoords.deinit();
    self.normals.deinit();
    self.faces.deinit();
}
