// Copyright © 2021 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const Self = @This();

const Colour = union(enum) {
    none,
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,

    @"256": u8,
    rgb: [3]u8,
};

fg: Colour = .white,
bg: Colour = .none,

bold: bool = false,
dimmed: bool = false,
italic: bool = false,
underline: bool = false,
blinking: bool = false,
reverse: bool = false,
hidden: bool = false,
overline: bool = false,
strikethrough: bool = false,

pub fn eql(self: Self, other: Self) bool {
    inline for (@typeInfo(Self).Struct.fields) |field| {
        if (@field(self, field.name) != @field(other, field.name)) return false;
    }
    return true;
}

pub fn dump(self: Self, writer: anytype) !void {
    try writer.writeAll("\x1B[0");
    if (self.bold) try writer.writeAll(";1");
    if (self.dimmed) try writer.writeAll(";2");
    if (self.italic) try writer.writeAll(";3");
    if (self.underline) try writer.writeAll(";4");
    if (self.blinking) try writer.writeAll(";5");
    if (self.reverse) try writer.writeAll(";7");
    if (self.hidden) try writer.writeAll(";8");
    if (self.overline) try writer.writeAll(";53");
    if (self.strikethrough) try writer.writeAll(";9");
    switch (self.fg) {
        .none => {},
        .black => try writer.writeAll(";30"),
        .red => try writer.writeAll(";31"),
        .green => try writer.writeAll(";32"),
        .yellow => try writer.writeAll(";33"),
        .blue => try writer.writeAll(";34"),
        .magenta => try writer.writeAll(";35"),
        .cyan => try writer.writeAll(";36"),
        .white => try writer.writeAll(";37"),
        .bright_black => try writer.writeAll(";90"),
        .bright_red => try writer.writeAll(";91"),
        .bright_green => try writer.writeAll(";92"),
        .bright_yellow => try writer.writeAll(";93"),
        .bright_blue => try writer.writeAll(";94"),
        .bright_magenta => try writer.writeAll(";95"),
        .bright_cyan => try writer.writeAll(";96"),
        .bright_white => try writer.writeAll(";97"),
        .@"256" => {
            try writer.writeAll(";38;5");
            try writer.print(";{d}", .{self.fg.@"256"});
        },
        .rgb => {
            try writer.writeAll(";38;2");
            try writer.print(";{d};{d};{d}", .{
                self.fg.rgb[0],
                self.fg.rgb[1],
                self.fg.rgb[2],
            });
        },
    }
    switch (self.bg) {
        .none => {},
        .black => try writer.writeAll(";40"),
        .red => try writer.writeAll(";41"),
        .green => try writer.writeAll(";42"),
        .yellow => try writer.writeAll(";43"),
        .blue => try writer.writeAll(";44"),
        .magenta => try writer.writeAll(";45"),
        .cyan => try writer.writeAll(";46"),
        .white => try writer.writeAll(";74"),
        .bright_black => try writer.writeAll(";100"),
        .bright_red => try writer.writeAll(";101"),
        .bright_green => try writer.writeAll(";102"),
        .bright_yellow => try writer.writeAll(";103"),
        .bright_blue => try writer.writeAll(";104"),
        .bright_magenta => try writer.writeAll(";105"),
        .bright_cyan => try writer.writeAll(";106"),
        .bright_white => try writer.writeAll(";107"),
        .@"256" => {
            try writer.writeAll(";48;5");
            try writer.print(";{d}", .{self.bg.@"256"});
        },
        .rgb => {
            try writer.writeAll(";48;2");
            try writer.print(";{d};{d};{d}", .{
                self.bg.rgb[0],
                self.bg.rgb[1],
                self.bg.rgb[2],
            });
        },
    }
    try writer.writeAll("m");
}
