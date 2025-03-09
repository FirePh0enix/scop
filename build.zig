const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "scop",
        .root_module = exe_mod,
    });

    // Compile the MiniLibX directly with Zig.
    exe.addCSourceFiles(.{
        .files = &.{
            "mlx/mlx_init.c",                   "mlx/mlx_new_window.c",          "mlx/mlx_pixel_put.c",             "mlx/mlx_loop.c",
            "mlx/mlx_mouse_hook.c",             "mlx/mlx_key_hook.c",            "mlx/mlx_expose_hook.c",           "mlx/mlx_loop_hook.c",
            "mlx/mlx_int_anti_resize_win.c",    "mlx/mlx_int_do_nothing.c",      "mlx/mlx_int_wait_first_expose.c", "mlx/mlx_int_get_visual.c",
            "mlx/mlx_flush_event.c",            "mlx/mlx_string_put.c",          "mlx/mlx_set_font.c",              "mlx/mlx_new_image.c",
            "mlx/mlx_get_data_addr.c",          "mlx/mlx_put_image_to_window.c", "mlx/mlx_get_color_value.c",       "mlx/mlx_clear_window.c",
            "mlx/mlx_xpm.c",                    "mlx/mlx_int_str_to_wordtab.c",  "mlx/mlx_destroy_window.c",        "mlx/mlx_int_param_event.c",
            "mlx/mlx_int_set_win_event_mask.c", "mlx/mlx_hook.c",                "mlx/mlx_rgb.c",                   "mlx/mlx_destroy_image.c",
            "mlx/mlx_mouse.c",                  "mlx/mlx_screen_size.c",         "mlx/mlx_destroy_display.c",
        },
    });

    exe.addCSourceFiles(.{
        .files = &.{"glad/src/glad.c"},
    });
    exe.addIncludePath(b.path("glad/include"));

    // Make MLX headers available to Zig code.
    const translate_mlx = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("c.h"),
    });

    exe.step.dependOn(&translate_mlx.step);
    exe.root_module.addImport("mlx", translate_mlx.addModule("mlx"));

    const argzon_dep = b.dependency("argzon", .{
        .target = target,
        .optimize = optimize,
    });
    const argzon_mod = argzon_dep.module("argzon");
    exe.root_module.addImport("argzon", argzon_mod);

    // Add dependencies of the MLX.
    exe.linkSystemLibrary("x11");
    exe.linkSystemLibrary("Xext");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
