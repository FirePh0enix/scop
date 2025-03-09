const std = @import("std");

const cos = std.math.cos;
const sin = std.math.sin;
const tan = std.math.tan;

pub const Vector2 = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,

    const SimdVec = @Vector(2, f32);

    inline fn toSimd(self: Vector2) SimdVec {
        return .{ self.x, self.y };
    }

    inline fn fromSimd(v: SimdVec) Vector2 {
        return .{ .x = v[0], .y = v[1] };
    }

    pub inline fn add(self: *const Vector2, rhs: Vector2) Vector2 {
        return fromSimd(self.toSimd() + rhs.toSimd());
    }

    pub inline fn sub(self: *const Vector2, rhs: Vector2) Vector2 {
        return fromSimd(self.toSimd() - rhs.toSimd());
    }

    pub inline fn scale(self: *const Vector2, scalar: f32) Vector2 {
        return fromSimd(self.toSimd() * scalar);
    }

    pub inline fn length(self: *const Vector2) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y);
    }
};

pub const Vector3 = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,

    pub const up = Vector3{ .y = 1.0 };
    pub const down = Vector3{ .y = -1.0 };
    pub const left = Vector3{ .x = -1.0 };
    pub const right = Vector3{ .x = 1.0 };
    pub const forward = Vector3{ .z = -1.0 };
    pub const backward = Vector3{ .z = 1.0 };

    pub const x_axis = Vector3{ .x = 1.0 };
    pub const y_axis = Vector3{ .y = 1.0 };
    pub const z_axis = Vector3{ .z = 1.0 };

    pub const inv_x_axis = Vector3{ .x = -1.0 };
    pub const inv_y_axis = Vector3{ .y = -1.0 };
    pub const inv_z_axis = Vector3{ .z = -1.0 };

    const SimdVec = @Vector(3, f32);

    inline fn toSimd(self: Vector3) SimdVec {
        return .{ self.x, self.y, self.z };
    }

    inline fn fromSimd(v: SimdVec) Vector3 {
        return .{ .x = v[0], .y = v[1], .z = v[2] };
    }

    pub inline fn inverse(self: *const Vector3) Vector3 {
        return Vector3{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
        };
    }

    pub inline fn xy(self: *const Vector3) Vector2 {
        return .{
            .x = self.x,
            .y = self.y,
        };
    }

    pub inline fn yz(self: *const Vector3) Vector2 {
        return .{
            .x = self.y,
            .y = self.z,
        };
    }

    pub inline fn add(self: *const Vector3, rhs: Vector3) Vector3 {
        return fromSimd(self.toSimd() + rhs.toSimd());
    }

    pub inline fn sub(self: *const Vector3, rhs: Vector3) Vector3 {
        return fromSimd(self.toSimd() - rhs.toSimd());
    }

    pub inline fn scale(self: *const Vector3, scalar: f32) Vector3 {
        return .{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    pub inline fn cross(self: *const Vector3, rhs: Vector3) Vector3 {
        return .{
            .x = self.y * rhs.z - self.z * rhs.y,
            .y = self.z * rhs.x - self.x * rhs.z,
            .z = self.x * rhs.y - self.y * rhs.x,
        };
    }

    pub inline fn length(self: *const Vector3) f32 {
        return std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub inline fn lengthSquared(self: *const Vector3) f32 {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }

    pub inline fn normalized(self: *const Vector3) Vector3 {
        const lengthValue = self.length();

        return .{
            .x = self.x / lengthValue,
            .y = self.y / lengthValue,
            .z = self.z / lengthValue,
        };
    }

    pub inline fn dot(self: *const Vector3, rhs: Vector3) f32 {
        return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z;
    }
};

pub const Vector4 = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,
    w: f32 = 0.0,

    pub fn fromVector3(v: Vector3, w: f32) Vector4 {
        return .{
            .x = v.x,
            .y = v.y,
            .z = v.z,
            .w = w,
        };
    }
};

pub const Matrix4 = struct {
    m00: f32 = 0.0,
    m01: f32 = 0.0,
    m02: f32 = 0.0,
    m03: f32 = 0.0,
    m10: f32 = 0.0,
    m11: f32 = 0.0,
    m12: f32 = 0.0,
    m13: f32 = 0.0,
    m20: f32 = 0.0,
    m21: f32 = 0.0,
    m22: f32 = 0.0,
    m23: f32 = 0.0,
    m30: f32 = 0.0,
    m31: f32 = 0.0,
    m32: f32 = 0.0,
    m33: f32 = 0.0,

    pub fn identity() Matrix4 {
        return .{
            .m00 = 1.0,
            .m11 = 1.0,
            .m22 = 1.0,
            .m33 = 1.0,
        };
    }

    pub fn projection(fov: f32, w: usize, h: usize, near: f32, far: f32) Matrix4 {
        const aspect_ratio = @as(f32, @floatFromInt(h)) / @as(f32, @floatFromInt(w));
        const fov_rad = 1.0 / tan(std.math.degreesToRadians(fov * 0.5));

        return .{
            .m00 = aspect_ratio * fov_rad,
            .m11 = fov_rad,
            .m22 = -(far + near) / (far - near),
            .m23 = -1.0, // or m32
            .m32 = (-2.0 * far * near) / (far - near), // or m23
        };
    }

    pub fn translation(t: Vector3) Matrix4 {
        return .{
            .m00 = 1.0,
            .m11 = 1.0,
            .m22 = 1.0,
            .m33 = 1.0,
            .m30 = t.x,
            .m31 = t.y,
            .m32 = t.z,
        };
    }

    pub fn model(t: Vector3, r: Vector3) Matrix4 {
        return translation(t).mul(rotation(r));
    }

    pub fn modelWithOffset(t: Vector3, r: Vector3, o: Vector3) Matrix4 {
        return translation(t).mul(rotation(r).mul(translation(o.inverse())));
    }

    fn rotationXInternal(c: f32, s: f32) Matrix4 {
        return .{
            .m00 = 1.0,
            .m11 = c,
            .m12 = s, // or the oposite
            .m21 = -s,
            .m22 = c,
            .m33 = 1.0,
        };
    }

    fn rotationYInternal(c: f32, s: f32) Matrix4 {
        return .{
            .m00 = c,
            .m02 = -s,
            .m11 = 1.0,
            .m20 = s,
            .m22 = c,
            .m33 = 1.0,
        };
    }

    fn rotationZInternal(c: f32, s: f32) Matrix4 {
        return .{
            .m00 = c,
            .m01 = s,
            .m10 = -s,
            .m11 = c,
            .m22 = 1.0,
            .m33 = 1.0,
        };
    }

    fn rotation(r: Vector3) Matrix4 {
        const c = Vector3{ .x = cos(r.x), .y = cos(r.y), .z = cos(r.z) };
        const s = Vector3{ .x = sin(r.x), .y = sin(r.y), .z = sin(r.z) };

        const rotx = rotationXInternal(c.x, s.x);
        const roty = rotationYInternal(c.y, s.y);
        const rotz = rotationZInternal(c.z, s.z);

        return roty.mulMat4(rotz).mulMat4(rotx);
    }

    pub inline fn mul(self: *const Matrix4, rhs: anytype) @TypeOf(rhs) {
        switch (@TypeOf(rhs)) {
            Vector3 => return self.mulVector3(rhs),
            Matrix4 => return self.mulMat4(rhs),
            else => @compileError("unable to multiply a matrix to a " ++ @typeName(@TypeOf(rhs))),
        }
    }

    pub inline fn mulMat4(self: *const Matrix4, rhs: Matrix4) Matrix4 {
        return .{
            .m00 = self.m00 * rhs.m00 + self.m10 * rhs.m01 + self.m20 * rhs.m02 + self.m30 * rhs.m03,
            .m10 = self.m00 * rhs.m10 + self.m10 * rhs.m11 + self.m20 * rhs.m12 + self.m30 * rhs.m13,
            .m20 = self.m00 * rhs.m20 + self.m10 * rhs.m21 + self.m20 * rhs.m22 + self.m30 * rhs.m23,
            .m30 = self.m00 * rhs.m30 + self.m10 * rhs.m31 + self.m20 * rhs.m32 + self.m30 * rhs.m33,
            .m01 = self.m01 * rhs.m00 + self.m11 * rhs.m01 + self.m21 * rhs.m02 + self.m31 * rhs.m03,
            .m11 = self.m01 * rhs.m10 + self.m11 * rhs.m11 + self.m21 * rhs.m12 + self.m31 * rhs.m13,
            .m21 = self.m01 * rhs.m20 + self.m11 * rhs.m21 + self.m21 * rhs.m22 + self.m31 * rhs.m23,
            .m31 = self.m01 * rhs.m30 + self.m11 * rhs.m31 + self.m21 * rhs.m32 + self.m31 * rhs.m33,
            .m02 = self.m02 * rhs.m00 + self.m12 * rhs.m01 + self.m22 * rhs.m02 + self.m32 * rhs.m03,
            .m12 = self.m02 * rhs.m10 + self.m12 * rhs.m11 + self.m22 * rhs.m12 + self.m32 * rhs.m13,
            .m22 = self.m02 * rhs.m20 + self.m12 * rhs.m21 + self.m22 * rhs.m22 + self.m32 * rhs.m23,
            .m32 = self.m02 * rhs.m30 + self.m12 * rhs.m31 + self.m22 * rhs.m32 + self.m32 * rhs.m33,
            .m03 = self.m03 * rhs.m00 + self.m13 * rhs.m01 + self.m23 * rhs.m02 + self.m33 * rhs.m03,
            .m13 = self.m03 * rhs.m10 + self.m13 * rhs.m11 + self.m23 * rhs.m12 + self.m33 * rhs.m13,
            .m23 = self.m03 * rhs.m20 + self.m13 * rhs.m21 + self.m23 * rhs.m22 + self.m33 * rhs.m23,
            .m33 = self.m03 * rhs.m30 + self.m13 * rhs.m31 + self.m23 * rhs.m32 + self.m33 * rhs.m33,
        };
    }

    pub inline fn mulVector3(m: *const Matrix4, v: Vector3) Vector3 {
        const w = m.m03 * v.x + m.m13 * v.y + m.m23 * v.z + m.m33;

        var r = Vector3{
            .x = m.m00 * v.x + m.m10 * v.y + m.m20 * v.z + m.m30,
            .y = m.m01 * v.x + m.m11 * v.y + m.m21 * v.z + m.m31,
            .z = m.m02 * v.x + m.m12 * v.y + m.m22 * v.z + m.m32,
        };

        r.x /= w;
        r.y /= w;
        // FIXME:
        // Commenting this code fix the projection problem in r3d_fill_triangle
        // r.z /= w;

        return r;
    }
};
