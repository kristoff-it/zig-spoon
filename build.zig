const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spoon_mod = b.addModule("spoon", .{
        .source_file = .{ .path = "import.zig" },
    });

    const tests = b.addTest(
        .{
            .root_source_file = .{ .path = "test_main.zig" },
            .target = target,
            .optimize = optimize,
        },
    );
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);

    {
        const exe = b.addExecutable(
            .{
                .name = "menu",
                .root_source_file = .{ .path = "example/menu.zig" },
                .target = target,
                .optimize = optimize,
            },
        );
        exe.addModule("spoon", spoon_mod);
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "menu-libc",
                .root_source_file = .{ .path = "example/menu.zig" },
                .target = target,
                .optimize = optimize,
            },
        );
        exe.addModule("spoon", spoon_mod);
        exe.linkLibC();
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "input-demo",
                .root_source_file = .{ .path = "example/input-demo.zig" },
                .target = target,
                .optimize = optimize,
            },
        );
        exe.addModule("spoon", spoon_mod);
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "colours",
                .root_source_file = .{ .path = "example/colours.zig" },
                .target = target,
                .optimize = optimize,
            },
        );
        exe.addModule("spoon", spoon_mod);
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "table-256-colours",
                .root_source_file = .{ .path = "example/table-256-colours.zig" },
                .target = target,
                .optimize = optimize,
            },
        );
        exe.addModule("spoon", spoon_mod);
        b.installArtifact(exe);
    }

    {
        const exe = b.addExecutable(
            .{
                .name = "terminfo",
                .root_source_file = .{ .path = "example/terminfo.zig" },
                .target = target,
                .optimize = optimize,
            },
        );
        exe.addModule("spoon", spoon_mod);
        b.installArtifact(exe);
    }
}
