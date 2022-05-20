const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const tests = b.addTest("test_main.zig");
    tests.setTarget(target);
    tests.setBuildMode(mode);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&tests.step);

    {
        const exe = b.addExecutable("menu", "example/menu.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackagePath("spoon", "import.zig");
        exe.install();
    }

    {
        const exe = b.addExecutable("input-demo", "example/input-demo.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackagePath("spoon", "import.zig");
        exe.install();
    }

    {
        const exe = b.addExecutable("colours", "example/colours.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackagePath("spoon", "import.zig");
        exe.install();
    }

    {
        const exe = b.addExecutable("table-256-colours", "example/table-256-colours.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackagePath("spoon", "import.zig");
        exe.install();
    }
}
