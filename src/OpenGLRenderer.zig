const std = @import("std");
const c = @import("mlx");
const math = @import("math.zig");

const Allocator = std.mem.Allocator;
const Matrix4 = math.Matrix4;
const Vector2 = math.Vector2;
const Vector3 = math.Vector3;
const Vector4 = math.Vector4;
const Mesh = @import("Mesh.zig");
const Texture = @import("Texture.zig");
const Settings = @import("Settings.zig");

allocator: Allocator,

var settings: Settings = undefined;
var mesh: Mesh = undefined;
var texture: ?Texture = null;
var rotation_y: f32 = 0.0;

pub fn init(allocator: Allocator, settings_: Settings, mesh_: Mesh, texture_: ?Texture) @This() {
    settings = settings_;
    mesh = mesh_;
    texture = texture_;

    return .{ .allocator = allocator };
}

pub fn run(self: *const @This()) !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS)) {
        return error.UnableToInitialize;
    }

    const window = c.SDL_CreateWindow("scop", @intCast(settings.window_width), @intCast(settings.window_height), c.SDL_WINDOW_OPENGL);

    if (window == null) {
        return error.UnableToCreateWindow;
    }

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 2);

    const context = c.SDL_GL_CreateContext(window);

    _ = c.SDL_GL_MakeCurrent(window, context);

    if (c.gladLoadGLLoader(@ptrCast(&c.SDL_GL_GetProcAddress)) == 0) {
        return error.UnableToInitializeGlad;
    }

    var running = true;

    //
    // Setup OpenGL buffers
    //

    // Create the vertex buffer

    var indices = try std.ArrayList(u32).initCapacity(self.allocator, mesh.faces.items.len * 3);
    defer indices.deinit();

    for (mesh.faces.items) |face| {
        try indices.append(face.vertices[0]);
        try indices.append(face.vertices[1]);
        try indices.append(face.vertices[2]);
    }

    var vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);

    var vbo: c.GLuint = undefined;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(@sizeOf(f32) * mesh.vertices.items.len), @ptrCast(mesh.vertices.items.ptr), c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    var ebo: c.GLuint = undefined;
    c.glGenBuffers(1, &ebo);
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @intCast(@sizeOf(u32) * indices.items.len), @ptrCast(indices.items.ptr), c.GL_STATIC_DRAW);

    // Compile & Link shaders
    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    c.glShaderSource(vertex_shader, 1, @ptrCast(&vertex_shader_source), null);
    c.glCompileShader(vertex_shader);

    c.glShaderSource(fragment_shader, 1, @ptrCast(&fragment_shader_source), null);
    c.glCompileShader(fragment_shader);

    const program = c.glCreateProgram();
    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);
    c.glLinkProgram(program);

    const model_matrix_location = c.glGetUniformLocation(program, "modelMatrix");
    const view_matrix_location = c.glGetUniformLocation(program, "viewMatrix");
    const projection_matrix_location = c.glGetUniformLocation(program, "projectionMatrix");

    const model_matrix = Matrix4.model(Vector3{ .x = settings.model_x, .y = settings.model_y, .z = settings.model_z }, Vector3{ .y = rotation_y });
    const view_matrix = Matrix4.identity();
    const projection_matrix = Matrix4.projection(70.0, settings.window_width, settings.window_height, 0.01, 1000.0);

    c.glDeleteShader(vertex_shader);
    c.glDeleteShader(fragment_shader);

    c.glUseProgram(program);

    c.glUniformMatrix4fv(model_matrix_location, 1, c.GL_FALSE, @ptrCast(&model_matrix));
    c.glUniformMatrix4fv(view_matrix_location, 1, c.GL_FALSE, @ptrCast(&view_matrix));
    c.glUniformMatrix4fv(projection_matrix_location, 1, c.GL_FALSE, @ptrCast(&projection_matrix));

    c.glViewport(0, 0, 1280, 720);

    while (running) {
        var event: c.SDL_Event = undefined;

        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_WINDOW_CLOSE_REQUESTED or event.type == c.SDL_EVENT_QUIT) {
                running = false;
            }
        }

        // Render the model using OpenGL
        c.glUseProgram(program);

        c.glBindVertexArray(vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);

        c.glDrawElements(c.GL_TRIANGLES, @intCast(indices.items.len), c.GL_UNSIGNED_INT, null);

        _ = c.SDL_GL_SwapWindow(window);
    }

    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}

const vertex_shader_source: []const u8 =
    \\  #version 330 core
    \\
    \\  layout(location = 0) in vec3 aPos;
    \\
    \\  out vec4 vertexColor;
    \\
    \\  uniform mat4 modelMatrix;
    \\  uniform mat4 viewMatrix;
    \\  uniform mat4 projectionMatrix;
    \\
    \\  void main()
    \\  {
    \\      mat4 mvp = modelMatrix * viewMatrix * projectionMatrix;
    \\
    \\      gl_Position = mvp * vec4(aPos, 1.0);
    \\      vertexColor = vec4(0.5, 0.0, 0.0, 1.0);
    \\  }
;

const fragment_shader_source: []const u8 =
    \\  #version 330 core
    \\
    \\  in vec4 vertexColor;
    \\
    \\  out vec4 fragColor;
    \\
    \\  void main()
    \\  {
    \\      fragColor = vertexColor;
    \\  }
;
