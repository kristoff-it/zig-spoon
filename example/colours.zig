// This example programs demonstrates that spoon.Attribute can also be used
// stand-alone without using spoon.Term.

const std = @import("std");
const io = std.io;

const spoon = @import("spoon");

const red = spoon.Attribute{ .fg = .red, .italic = true };
const green = spoon.Attribute{ .fg = .green, .blinking = true };
const blue = spoon.Attribute{ .fg = .blue, .bold = true };
const cyan = spoon.Attribute{ .fg = .cyan, .reverse = true };
const reset = spoon.Attribute{};

pub fn main() !void {
    const writer = io.getStdOut().writer();

    try red.dump(writer);
    try writer.writeAll("foo ");
    try green.dump(writer);
    try writer.writeAll("bar ");
    try blue.dump(writer);
    try writer.writeAll("baz ");
    try cyan.dump(writer);
    try writer.writeAll("spoon\n");

    try reset.dump(writer);
}
