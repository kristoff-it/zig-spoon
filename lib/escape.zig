// Copyright © 2021 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

pub fn hideCursor(writer: anytype) !void {
    try writer.writeAll("\x1B[?25l");
}

pub fn showCursor(writer: anytype) !void {
    try writer.writeAll("\x1B[?25h");
}

pub fn enableKittyKeyboard(writer: anytype) !void {
    // https://sw.kovidgoyal.net/kitty/keyboard-protocol/
    // This enables an alternative input mode, that makes it possible, among
    // others, to unambigously identify the escape key without waiting for
    // a timer to run out. And implementing it can be implemented in a backwards
    // compatible manner, so that the same code can handle kitty-enabled
    // terminals as well as sad terminals.
    //
    // Must be enabled after entering the alt screen and disabled before leaving
    // it.
    try writer.writeAll("\x1B[>1u");
}

pub fn disableKittyKeyboard(writer: anytype) !void {
    // https://sw.kovidgoyal.net/kitty/keyboard-protocol/
    try writer.writeAll("\x1B[<u");
}

pub fn enterAlt(writer: anytype) !void {
    try writer.writeAll("\x1B[s"); // Save cursor position.
    try writer.writeAll("\x1B[?47h"); // Save screen.
    try writer.writeAll("\x1B[?1049h"); // Enable alternative buffer.
}

pub fn leaveAlt(writer: anytype) !void {
    try writer.writeAll("\x1B[?1049l"); // Disable alternative buffer.
    try writer.writeAll("\x1B[?47l"); // Restore screen.
    try writer.writeAll("\x1B[u"); // Restore cursor position.
}

pub fn clear(writer: anytype) !void {
    try writer.writeAll("\x1B[2J");
}

pub fn moveCursor(writer: anytype, row: usize, col: usize) !void {
    // The values for this escape sequence are 1-based.
    _ = try writer.print("\x1B[{};{}H", .{ row + 1, col + 1 });
}

pub fn moveCursorHome(writer: anytype) !void {
    try writer.writeAll("\x1B[H");
}

pub fn attributeReset(writer: anytype) !void {
    try writer.writeAll("\x1B[0m");
}

pub fn overwriteMode(writer: anytype) !void {
    try writer.writeAll("\x1B[4l");
}

pub fn enableAutoWrap(writer: anytype) !void {
    // Per https://espterm.github.io/docs/VT100%20escape%20codes.html
    try writer.writeAll("\x1B[?7h");
}

pub fn resetAutoWrap(writer: anytype) !void {
    // Per https://espterm.github.io/docs/VT100%20escape%20codes.html
    try writer.writeAll("\x1B[?7l");
}

pub fn resetAutoRepeat(writer: anytype) !void {
    // Per https://espterm.github.io/docs/VT100%20escape%20codes.html
    try writer.writeAll("\x1B[?8l");
}

pub fn resetAutoInterlace(writer: anytype) !void {
    // Per https://espterm.github.io/docs/VT100%20escape%20codes.html
    try writer.writeAll("\x1B[?9l");
}

pub fn startSync(writer: anytype) !void {
    try writer.writeAll("\x1BP=1s\x1B\\");
}

pub fn endSync(writer: anytype) !void {
    try writer.writeAll("\x1BP=2s\x1B\\");
}
