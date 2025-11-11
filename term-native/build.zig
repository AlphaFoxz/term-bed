const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimizeOpt = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const lib = b.addLibrary(.{
        .name = "tui_app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/exports.zig"),
            .target = target,
            .optimize = optimizeOpt,
        }),
        .linkage = .dynamic,
    });
    lib.linkSystemLibrary("c");
    b.installArtifact(lib);
}

fn createModule(
    b: *std.Build,
    codePath: []const u8,
    target: std.Build.ResolvedTarget,
    optimizeOpt: std.builtin.OptimizeMode,
) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path(codePath),
        .target = target,
        .optimize = optimizeOpt,
    });
}

fn createDependency(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimizeOpt: std.builtin.OptimizeMode,
) *std.Build.Module {
    const dep = b.dependency(name, .{
        .target = target,
        .optimize = optimizeOpt,
    });
    return dep.module(name);
}
