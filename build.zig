const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("menu", "example/menu.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("spoon", "import.zig");
    exe.install();

    // TODO write man page
    //b.installFile("doc/nfm.1", "share/man/man1/nfm.1");
}
