const std = @import("std");
const io = std.io;

const spoon = @import("spoon");

const title_colour = spoon.Attribute.Colour.fromDescription("7") catch
    @compileError("bad colour description");
const title = spoon.Attribute{ .fg = title_colour, .bold = true };
const reset = spoon.Attribute{};

pub fn main() !void {
    const writer = io.getStdOut().writer();

    var colour: u8 = 0;
    var column: usize = 0;

    try writeTitle(writer, "Standard colours (0 to 15)");
    while (colour < 16) : (colour += 1) {
        const attr = spoon.Attribute{ .bg = .{ .@"256" = colour } };

        try attr.dump(writer);
        try writer.writeAll("    ");
        try reset.dump(writer);

        column += 1;
    }

    try writeTitle(writer, "\n6x6x6 cubic palette (16 to 231)");
    column = 0;
    while (colour < 232) : (colour += 1) {
        const attr = spoon.Attribute{ .bg = .{ .@"256" = colour } };

        if (column == 16) {
            column = 0;
            try writer.writeByte('\n');
        }

        try attr.dump(writer);
        try writer.writeAll("    ");
        try reset.dump(writer);

        column += 1;
    }

    try writeTitle(writer, "\nGrayscale (232 to 255)");
    column = 0;
    while (colour < 256) : (colour += 1) {
        const attr = spoon.Attribute{ .bg = .{ .@"256" = colour } };

        if (column == 16) {
            column = 0;
            try writer.writeByte('\n');
        }

        try attr.dump(writer);
        try writer.writeAll("    ");
        try reset.dump(writer);

        column += 1;

        if (colour == 255) break;
    }

    try writer.writeByte('\n');
}

fn writeTitle(writer: anytype, bytes: []const u8) !void {
    try title.dump(writer);
    try writer.writeByte('\n');
    try writer.writeAll(bytes);
    try writer.writeByte('\n');
    try reset.dump(writer);
}
