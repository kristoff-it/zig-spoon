// Copyright © 2022 Hugo Machet
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");
const ascii = std.ascii;
const fmt = std.fmt;
const mem = std.mem;

const Colour = @import("Attribute.zig").Colour;

/// A parser to convert an UTF8 string to an Attribute.Colour union.
/// RGB colours: "0xRRGGBB"
/// 256 colours: "154"
/// ANSI colours: A string equal to one of Colour fields (case sensitive)
///
/// Examples:
///     var rgb = try parseColourDescription("0x2b45a7");
///         -> Attribute{ .rgb = { 43, 69, 167 } };
///     var 256 = try parseColourDescription("234");
///         -> Attribute{ .@"256" = 234 };
///     var ansi = try parseColourDescription("red");
///         -> Attribute{ .red };
pub fn parseColourDescription(s: []const u8) !Colour {
    if (s.len == 0) return error.BadColourDescription;

    if (ascii.isDigit(s[0])) {
        if (s.len == "0xRRGGBB".len and s[0] == '0' and s[1] == 'x') {
            return Colour{ .rgb = try hexToRgb(s[2..]) };
        } else {
            return Colour{
                .@"256" = fmt.parseUnsigned(u8, s, 10) catch return error.BadColourDescription,
            };
        }
    } else if (mem.eql(u8, s, "none")) {
        return .none;
    } else if (mem.eql(u8, s, "black")) {
        return .black;
    } else if (mem.eql(u8, s, "red")) {
        return .red;
    } else if (mem.eql(u8, s, "green")) {
        return .green;
    } else if (mem.eql(u8, s, "yellow")) {
        return .yellow;
    } else if (mem.eql(u8, s, "blue")) {
        return .blue;
    } else if (mem.eql(u8, s, "magenta")) {
        return .magenta;
    } else if (mem.eql(u8, s, "cyan")) {
        return .cyan;
    } else if (mem.eql(u8, s, "white")) {
        return .white;
    } else if (mem.eql(u8, s, "bright_black")) {
        return .bright_black;
    } else if (mem.eql(u8, s, "bright_red")) {
        return .bright_red;
    } else if (mem.eql(u8, s, "bright_green")) {
        return .bright_green;
    } else if (mem.eql(u8, s, "bright_yellow")) {
        return .bright_yellow;
    } else if (mem.eql(u8, s, "bright_blue")) {
        return .bright_blue;
    } else if (mem.eql(u8, s, "bright_magenta")) {
        return .bright_magenta;
    } else if (mem.eql(u8, s, "bright_cyan")) {
        return .bright_cyan;
    } else if (mem.eql(u8, s, "bright_white")) {
        return .bright_white;
    } else {
        return error.BadColourDescription;
    }
}

/// Convert a string in the format "0xRRGGBB" to [3]u8.
fn hexToRgb(s: []const u8) ![3]u8 {
    if (s.len != 6) return error.BadRgbFormat;
    const r = fmt.parseUnsigned(u8, s[0..2], 16) catch return error.BadRgbFormat;
    const g = fmt.parseUnsigned(u8, s[2..4], 16) catch return error.BadRgbFormat;
    const b = fmt.parseUnsigned(u8, s[4..], 16) catch return error.BadRgbFormat;
    return [3]u8{ r, g, b };
}

test "parse colours string (good input)" {
    const testing = std.testing;
    try testing.expectEqual(
        Colour{ .rgb = .{ 255, 255, 255 } },
        try parseColourDescription("0xffffff"),
    );
    try testing.expectEqual(
        Colour{ .rgb = .{ 0, 0, 0 } },
        try parseColourDescription("0x000000"),
    );
    try testing.expectEqual(
        Colour{ .rgb = .{ 0, 169, 143 } },
        try parseColourDescription("0x00a98f"),
    );
    try testing.expectEqual(
        Colour{ .@"256" = 0 },
        try parseColourDescription("0"),
    );
    try testing.expectEqual(
        Colour{ .@"256" = 7 },
        try parseColourDescription("007"),
    );
    try testing.expectEqual(
        Colour{ .@"256" = 7 },
        try parseColourDescription("0000000000000000007"),
    );
    try testing.expectEqual(
        Colour{ .@"256" = 237 },
        try parseColourDescription("237"),
    );
    try testing.expectEqual(
        Colour.bright_black,
        try parseColourDescription("bright_black"),
    );
    try testing.expectEqual(
        Colour.blue,
        try parseColourDescription("blue"),
    );
}

test "parse colours string (bad input)" {
    const testing = std.testing;
    try testing.expectError(error.BadRgbFormat, parseColourDescription("0xppttjj"));
    try testing.expectError(error.BadColourDescription, parseColourDescription("0xfff"));
    try testing.expectError(error.BadColourDescription, parseColourDescription("0x"));
    try testing.expectError(error.BadColourDescription, parseColourDescription("0Xffffff"));
    try testing.expectError(error.BadColourDescription, parseColourDescription(""));
    try testing.expectError(error.BadColourDescription, parseColourDescription("xffffff"));
    try testing.expectError(error.BadColourDescription, parseColourDescription("ffffff"));
    try testing.expectError(error.BadColourDescription, parseColourDescription("blu"));
    try testing.expectError(error.BadColourDescription, parseColourDescription("bLue"));
    try testing.expectError(error.BadColourDescription, parseColourDescription("256"));
}
