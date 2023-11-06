const std = @import("std");

const spoon = @import("spoon");

pub fn main() !void {
    const ti = try spoon.Terminfo.init();
    _ = ti;
}
