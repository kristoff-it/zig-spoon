// Copyright © 2021 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const Event = @import("event.zig").Event;

pub fn legacyEscapeSequence(bytes: []const u8) ?Event {
    @setEvalBranchQuota(5000);
    const legacy_escape_sequences = std.ComptimeStringMap(Event, .{
        .{ "[A", .{ .key = .arrow_up } },
        .{ "OA", .{ .key = .arrow_up } },
        .{ "[B", .{ .key = .arrow_down } },
        .{ "OB", .{ .key = .arrow_down } },
        .{ "[C", .{ .key = .arrow_right } },
        .{ "OC", .{ .key = .arrow_right } },
        .{ "[D", .{ .key = .arrow_left } },
        .{ "OD", .{ .key = .arrow_left } },
        .{ "[2~", .{ .key = .insert } },
        .{ "[3~", .{ .key = .delete } },
        .{ "[5~", .{ .key = .page_up } },
        .{ "[6~", .{ .key = .page_down } },
        .{ "[F", .{ .key = .end } },
        .{ "OF", .{ .key = .end } },
        .{ "[4~", .{ .key = .home } },
        .{ "[8~", .{ .key = .home } },
        .{ "[H", .{ .key = .home } },
        .{ "[1~", .{ .key = .home } },
        .{ "[7~", .{ .key = .home } },
        .{ "[H~", .{ .key = .home } },
        .{ "OP", .{ .key = .{ .function = 1 } } },
        .{ "OQ", .{ .key = .{ .function = 2 } } },
        .{ "OR", .{ .key = .{ .function = 3 } } },
        .{ "OS", .{ .key = .{ .function = 4 } } },
        .{ "[P", .{ .key = .{ .function = 1 } } },
        .{ "[Q", .{ .key = .{ .function = 2 } } },
        .{ "[R", .{ .key = .{ .function = 3 } } },
        .{ "[S", .{ .key = .{ .function = 4 } } },
        .{ "[15~", .{ .key = .{ .function = 5 } } },
        .{ "[17~", .{ .key = .{ .function = 6 } } },
        .{ "[18~", .{ .key = .{ .function = 7 } } },
        .{ "[19~", .{ .key = .{ .function = 8 } } },
        .{ "[20~", .{ .key = .{ .function = 9 } } },
        .{ "[21~", .{ .key = .{ .function = 10 } } },
        .{ "[23~", .{ .key = .{ .function = 11 } } },
        .{ "[24~", .{ .key = .{ .function = 12 } } },
        .{ "a", .{ .key = .{ .ascii = 'a' }, .mod_alt = true } },
        .{ "b", .{ .key = .{ .ascii = 'b' }, .mod_alt = true } },
        .{ "c", .{ .key = .{ .ascii = 'c' }, .mod_alt = true } },
        .{ "d", .{ .key = .{ .ascii = 'd' }, .mod_alt = true } },
        .{ "e", .{ .key = .{ .ascii = 'e' }, .mod_alt = true } },
        .{ "f", .{ .key = .{ .ascii = 'f' }, .mod_alt = true } },
        .{ "g", .{ .key = .{ .ascii = 'g' }, .mod_alt = true } },
        .{ "h", .{ .key = .{ .ascii = 'h' }, .mod_alt = true } },
        .{ "i", .{ .key = .{ .ascii = 'i' }, .mod_alt = true } },
        .{ "j", .{ .key = .{ .ascii = 'j' }, .mod_alt = true } },
        .{ "k", .{ .key = .{ .ascii = 'k' }, .mod_alt = true } },
        .{ "l", .{ .key = .{ .ascii = 'l' }, .mod_alt = true } },
        .{ "m", .{ .key = .{ .ascii = 'm' }, .mod_alt = true } },
        .{ "n", .{ .key = .{ .ascii = 'n' }, .mod_alt = true } },
        .{ "o", .{ .key = .{ .ascii = 'o' }, .mod_alt = true } },
        .{ "p", .{ .key = .{ .ascii = 'p' }, .mod_alt = true } },
        .{ "q", .{ .key = .{ .ascii = 'q' }, .mod_alt = true } },
        .{ "r", .{ .key = .{ .ascii = 'r' }, .mod_alt = true } },
        .{ "s", .{ .key = .{ .ascii = 's' }, .mod_alt = true } },
        .{ "t", .{ .key = .{ .ascii = 't' }, .mod_alt = true } },
        .{ "u", .{ .key = .{ .ascii = 'u' }, .mod_alt = true } },
        .{ "v", .{ .key = .{ .ascii = 'v' }, .mod_alt = true } },
        .{ "w", .{ .key = .{ .ascii = 'w' }, .mod_alt = true } },
        .{ "x", .{ .key = .{ .ascii = 'x' }, .mod_alt = true } },
        .{ "y", .{ .key = .{ .ascii = 'y' }, .mod_alt = true } },
        .{ "z", .{ .key = .{ .ascii = 'z' }, .mod_alt = true } },
    });
    return legacy_escape_sequences.get(bytes);
}

pub fn legacyCtrlCode(byte: u8) ?Event {
    return switch (byte) {
        'a' & '\x1f' => Event{ .key = .{ .ascii = 'a' }, .mod_ctrl = true },
        'b' & '\x1f' => Event{ .key = .{ .ascii = 'b' }, .mod_ctrl = true },
        'c' & '\x1f' => Event{ .key = .{ .ascii = 'c' }, .mod_ctrl = true },
        'd' & '\x1f' => Event{ .key = .{ .ascii = 'd' }, .mod_ctrl = true },
        'e' & '\x1f' => Event{ .key = .{ .ascii = 'e' }, .mod_ctrl = true },
        'f' & '\x1f' => Event{ .key = .{ .ascii = 'f' }, .mod_ctrl = true },
        'g' & '\x1f' => Event{ .key = .{ .ascii = 'g' }, .mod_ctrl = true },
        'h' & '\x1f' => Event{ .key = .{ .ascii = 'h' }, .mod_ctrl = true },
        'i' & '\x1f' => Event{ .key = .{ .ascii = '\t' } },
        'j' & '\x1f' => Event{ .key = .{ .ascii = 'j' }, .mod_ctrl = true },
        'k' & '\x1f' => Event{ .key = .{ .ascii = 'k' }, .mod_ctrl = true },
        'l' & '\x1f' => Event{ .key = .{ .ascii = 'l' }, .mod_ctrl = true },
        'm' & '\x1f' => Event{ .key = .{ .ascii = '\n' } },
        'n' & '\x1f' => Event{ .key = .{ .ascii = 'n' }, .mod_ctrl = true },
        'o' & '\x1f' => Event{ .key = .{ .ascii = 'o' }, .mod_ctrl = true },
        'p' & '\x1f' => Event{ .key = .{ .ascii = 'p' }, .mod_ctrl = true },
        'q' & '\x1f' => Event{ .key = .{ .ascii = 'q' }, .mod_ctrl = true },
        'r' & '\x1f' => Event{ .key = .{ .ascii = 'r' }, .mod_ctrl = true },
        's' & '\x1f' => Event{ .key = .{ .ascii = 's' }, .mod_ctrl = true },
        't' & '\x1f' => Event{ .key = .{ .ascii = 't' }, .mod_ctrl = true },
        'u' & '\x1f' => Event{ .key = .{ .ascii = 'u' }, .mod_ctrl = true },
        'v' & '\x1f' => Event{ .key = .{ .ascii = 'v' }, .mod_ctrl = true },
        'x' & '\x1f' => Event{ .key = .{ .ascii = 'x' }, .mod_ctrl = true },
        'y' & '\x1f' => Event{ .key = .{ .ascii = 'y' }, .mod_ctrl = true },
        'z' & '\x1f' => Event{ .key = .{ .ascii = 'z' }, .mod_ctrl = true },
        else => null,
    };
}

pub fn kittyEscapeSeqeunce(bytes: []const u8) ?Event {
    if (bytes.len < 3) return null;
    if (bytes[0] == '[') {
        switch (bytes[bytes.len - 1]) {
            'u' => return kittyEscapeSequenceU(bytes[1 .. bytes.len - 1]),
            '~' => return kittyEscapeSequenceTilde(bytes[1 .. bytes.len - 1]),
            'A', 'B', 'C', 'D', 'H', 'F' => {
                var ev = Event{ .key = switch (bytes[bytes.len - 1]) {
                    'A' => .arrow_up,
                    'B' => .arrow_down,
                    'C' => .arrow_right,
                    'D' => .arrow_left,
                    'H' => .home,
                    'F' => .end,
                    else => unreachable,
                } };
                // The kitty codes for the arrow keys always looks like this:
                // [1;<mod>[ABCD]
                const mod = bytes["[1;".len .. bytes.len - 1];
                kittyModifiers(&ev, mod);
                return ev;
            },
            else => return null,
        }
    }
    return null;
}

fn kittyEscapeSequenceU(bytes: []const u8) ?Event {
    var it = mem.tokenize(u8, bytes, ";");
    const key = fmt.parseInt(u8, it.next() orelse return null, 10) catch return null;
    var ev = Event{ .key = switch (key) {
        27 => .escape,
        13 => .{ .ascii = '\n' },
        else => .{ .ascii = key },
    } };
    if (it.next()) |mod| kittyModifiers(&ev, mod);
    return ev;
}

fn kittyEscapeSequenceTilde(bytes: []const u8) ?Event {
    var it = mem.tokenize(u8, bytes, ";");
    const key = fmt.parseInt(u8, it.next() orelse return null, 10) catch return null;
    var ev = Event{ .key = switch (key) {
        2 => .insert,
        3 => .delete,
        5 => .page_up,
        6 => .page_down,
        7 => .home,
        8 => .end,
        11 => .{ .function = 1 },
        12 => .{ .function = 2 },
        13 => .{ .function = 3 },
        14 => .{ .function = 4 },
        15 => .{ .function = 5 },
        17 => .{ .function = 6 },
        18 => .{ .function = 7 },
        19 => .{ .function = 8 },
        20 => .{ .function = 9 },
        21 => .{ .function = 10 },
        23 => .{ .function = 11 },
        24 => .{ .function = 12 },
        else => return null,
    } };
    if (it.next()) |mod| kittyModifiers(&ev, mod);
    return ev;
}

fn kittyModifiers(ev: *Event, md: []const u8) void {
    const mod = (fmt.parseInt(u32, md, 10) catch return) - 1;
    if ((mod & 0b10) > 0) ev.mod_alt = true;
    if ((mod & 0b100) > 0) ev.mod_ctrl = true;
}
