const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // TODO write man page
    //b.installFile("doc/nfm.1", "share/man/man1/nfm.1");

    {
        const exe = b.addExecutable("menu", "example/menu.zig");
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
}
