// Copyright © 2021 - 2022 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");
const ascii = std.ascii;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;
const unicode = std.unicode;

const Attribute = @import("Attribute.zig");
const Event = @import("event.zig").Event;
const spells = @import("spells.zig");
const key_codes = @import("key-codes.zig").key_codes;

pub const UserRender = fn (self: *Self, rows: usize, columns: usize) anyerror!void;

const Self = @This();

cooked: bool,
cooked_termios: os.termios,

/// Size of the terminal, updated when SIGWINCH is received.
width: usize,
height: usize,

tty: fs.File,
stdout: io.BufferedWriter(4096, fs.File.Writer),

user_render: UserRender,

// TODO options struct
//      -> IO read mode
pub fn init(self: *Self, ur: UserRender) !void {
    self.cooked = true;
    self.user_render = ur;
    self.tty = try fs.cwd().openFile(
        "/dev/tty",
        .{ .read = true, .write = true },
    );
    errdefer self.tty.close();
    self.stdout = io.bufferedWriter(self.tty.writer());
}

pub fn deinit(self: *Self) void {
    self.tty.close();
}

pub fn nextEvent(self: *Self) !?Event {
    var buffer: [1]u8 = undefined;
    const bytes_read = try self.tty.read(&buffer);
    if (bytes_read == 0) return null;

    if (buffer[0] == '\x1B') {
        // Oh no, an escape sequence! Let's try to read the rest of it.
        // Here we do not want the read syscall to immediately return, because
        // the rest of the escape sequence might not have been send yet.
        // Since however it is not actually guaranteed that there are additional
        // bytes and since escape sequences can have different lengths, we
        // tune read to return after a timeout instead of after a minimum amount
        // of read bytes.
        //
        // However if the terminal supports kitty mode, this should never
        // never timeout as the escape key also sends an escape sequence, not
        // just the escape character. Luckily the timeout does not mess with
        // kitty mode, so we can use the same code to handle both kitty and
        // legacy.
        var termios = try os.tcgetattr(self.tty.handle);
        termios.cc[os.system.V.TIME] = 1;
        termios.cc[os.system.V.MIN] = 0;
        try os.tcsetattr(self.tty.handle, .NOW, termios);

        var esc_buffer: [8]u8 = undefined;
        const esc_read = try self.tty.read(&esc_buffer);

        termios.cc[os.system.V.TIME] = 0;
        termios.cc[os.system.V.MIN] = 0;

        try os.tcsetattr(self.tty.handle, .NOW, termios);

        // TODO It can easiely happen that we accidentally swallow another
        //      keypress in legacy mode that is not part of an escape sequence,
        //      simply because the minimum available timeout you can set via
        //      termios is 100ms, which is pretty long. Some TUI software
        //      managed to detect the escape key despite this and we should
        //      probably do the same. However this is a low priority goal, as
        //      this problem does not occur when using kitty keyboard mode.

        if (esc_read == 0) return .escape;
        return key_codes.get(esc_buffer[0..esc_read]) orelse .unknown;
    }

    // Legacy codes for Ctrl-[a-z]. This is missing 'm', as that would match Enter.
    const chars = comptime blk: {
        var chars = [_]u8{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w' };
        for (chars) |*ch| ch.* &= '\x1f';
        break :blk chars;
    };
    for (chars) |char| if (buffer[0] == char) return Event{ .ctrl = char };

    return Event{ .ascii = buffer[0] };
}

/// Enter raw mode.
/// The information on the various flags and escape sequences is pieced
/// together from various sources, including termios(3) and
/// https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html.
/// TODO: IUTF8 ?
pub fn uncook(self: *Self) !void {
    if (!self.cooked) return;
    self.cooked = false;

    self.cooked_termios = try os.tcgetattr(self.tty.handle);
    errdefer self.cook() catch {};

    var raw = self.cooked_termios;

    //   ECHO: Stop the terminal from displaying pressed keys.
    // ICANON: Disable canonical ("cooked") mode. Allows us to read inputs
    //         byte-wise instead of line-wise.
    //   ISIG: Disable signals for Ctrl-C (SIGINT) and Ctrl-Z (SIGTSTP), so we
    //         can handle them as normal escape sequences.
    // IEXTEN: Disable input preprocessing. This allows us to handle Ctrl-V,
    //         which would otherwise be intercepted by some terminals.
    raw.lflag &= ~@as(
        os.system.tcflag_t,
        os.system.ECHO | os.system.ICANON | os.system.ISIG | os.system.IEXTEN,
    );

    //   IXON: Disable software control flow. This allows us to handle Ctrl-S
    //         and Ctrl-Q.
    //  ICRNL: Disable converting carriage returns to newlines. Allows us to
    //         handle Ctrl-J and Ctrl-M.
    // BRKINT: Disable converting sending SIGINT on break conditions. Likely has
    //         no effect on anything remotely modern.
    //  INPCK: Disable parity checking. Likely has no effect on anything
    //         remotely modern.
    // ISTRIP: Disable stripping the 8th bit of characters. Likely has no effect
    //         on anything remotely modern.
    raw.iflag &= ~@as(
        os.system.tcflag_t,
        os.system.IXON | os.system.ICRNL | os.system.BRKINT | os.system.INPCK | os.system.ISTRIP,
    );

    // Disable output processing. Common output processing includes prefixing
    // newline with a carriage return.
    raw.oflag &= ~@as(os.system.tcflag_t, os.system.OPOST);

    // Set the character size to 8 bits per byte. Likely has no efffect on
    // anything remotely modern.
    raw.cflag |= os.system.CS8;

    // With these settings, the read syscall will immediately return when it
    // can't get any bytes. This allows poll to drive our loop.
    raw.cc[os.system.V.TIME] = 0;
    raw.cc[os.system.V.MIN] = 0;

    try os.tcsetattr(self.tty.handle, .FLUSH, raw);

    const writer = self.stdout.writer();
    defer self.stdout.flush() catch {};

    try writer.writeAll(spells.save_cursor_position);
    try writer.writeAll(spells.save_cursor_position);
    try writer.writeAll(spells.enter_alt_buffer);

    try writer.writeAll(spells.enable_kitty_keyboard);

    try writer.writeAll(spells.overwrite_mode);
    try writer.writeAll(spells.reset_auto_wrap);
    try writer.writeAll(spells.reset_auto_repeat);
    try writer.writeAll(spells.reset_auto_interlace);
}

/// Enter cooked mode.
pub fn cook(self: *Self) !void {
    if (self.cooked) return;
    self.cooked = true;

    const writer = self.stdout.writer();
    defer self.stdout.flush() catch {};

    try writer.writeAll(spells.disable_kitty_keyboard);

    try writer.writeAll(spells.clear);
    try writer.writeAll(spells.leave_alt_buffer);
    try writer.writeAll(spells.restore_screen);
    try writer.writeAll(spells.restore_cursor_position);

    try writer.writeAll(spells.show_cursor);
    try writer.writeAll(spells.reset_attributes);
    try writer.writeAll(spells.reset_attributes);

    try os.tcsetattr(self.tty.handle, .FLUSH, self.cooked_termios);
}

pub fn fetchSize(self: *Self) !void {
    var size = mem.zeroes(os.system.winsize);
    const err = os.system.ioctl(self.tty.handle, os.system.T.IOCGWINSZ, @ptrToInt(&size));
    if (os.errno(err) != .SUCCESS) {
        return os.unexpectedErrno(@intToEnum(os.system.E, err));
    }
    self.height = size.ws_row;
    self.width = size.ws_col;
}

pub fn updateContent(self: *Self) !void {
    if (self.cooked) return;

    // Yes that's right, we write directly to stdout, not to a back buffer.
    // Thanks to the sync escape sequence, there should be no flickering
    // regardless. This makes spoon a lot more efficient, with the slight caveat
    // that you need to manually remember what changed and needs updating.
    const writer = self.stdout.writer();
    defer self.stdout.flush() catch {};

    try writer.writeAll(spells.start_sync);
    try writer.writeAll(spells.reset_attributes);

    try @call(.{}, self.user_render, .{ self, self.height, self.width });

    try writer.writeAll(spells.end_sync);
}

/// Clears all content.
pub fn clear(self: *Self) !void {
    const writer = self.stdout.writer();
    try writer.writeAll(spells.clear);
}

/// Move the cursor to the specified cell.
pub fn moveCursorTo(self: *Self, row: usize, col: usize) !void {
    const writer = self.stdout.writer();
    _ = try writer.print(spells.move_cursor_fmt, .{ row + 1, col + 1 });
}

/// Hide the cursor.
pub fn hideCursor(self: *Self) !void {
    const writer = self.stdout.writer();
    try writer.writeAll(spells.hide_cursor);
}

/// Show the cursor.
pub fn showCursor(self: *Self) !void {
    const writer = self.stdout.writer();
    try writer.writeAll(spells.show_cursor);
}

/// Set the text attributes for all following writes.
pub fn setAttribute(self: *Self, attr: Attribute) !void {
    const writer = self.stdout.writer();
    try attr.dump(writer);
}

/// Write a byte N times.
pub fn writeByteNTimes(self: *Self, byte: u8, n: usize) !void {
    const writer = self.stdout.writer();
    try writer.writeByteNTimes(byte, n);
}

/// Write at most `max_width` of `bytes`, abbreviating with '…' if necessary.
/// If the amount of written codepoints is less than `width`, returns the
/// difference, otherwise 0.
pub fn writeLine(self: *Self, max_width: usize, bytes: []const u8) !usize {
    const writer = self.stdout.writer();

    var view = unicode.Utf8View.init(bytes) catch {
        // Strings with unicode characters not recognized by zigs unicode
        // view are not uncommon. Treating those bytes as u8 chars is definitely
        // wrong, but better than crashing or displaying nothing.
        // TODO properly handle unicode
        return try writeLineNoUnicode(writer, max_width, bytes);
    };

    var written: usize = 0;
    var it = view.iterator();
    while (it.nextCodepointSlice()) |cp| : (written += 1) {
        if (written == max_width) {
            return 0;
        } else if (written == max_width - 1) {
            // We only have room for one more codepoint. Look ahead to see if we
            // need to draw '…'.
            if (it.nextCodepointSlice()) |_| {
                try writer.writeAll("…");
            } else {
                try writer.writeAll(cp);
            }
            return 0;
        } else {
            try writeCodePoint(writer, cp);
        }
    }
    return max_width - written;
}

fn writeLineNoUnicode(writer: anytype, max_width: usize, bytes: []const u8) !usize {
    if (bytes.len > max_width) {
        for (bytes[0 .. max_width - 1]) |char| try writeAscii(writer, char);
        try writer.writeAll("…");
        return 0;
    } else {
        for (bytes) |char| try writeAscii(writer, char);
        return max_width - bytes.len;
    }
}

fn writeCodePoint(writer: anytype, cp: []const u8) !void {
    if (cp.len == 1) {
        try writeAscii(writer, cp[0]);
    } else {
        try writer.writeAll(cp);
    }
}

fn writeAscii(writer: anytype, char: u8) !void {
    // Sanitize the input. We don't want to print an unwanted control character
    // to the terminal.
    if (char == '\n' or char == '\t' or char == '\r' or char == ' ') {
        try writer.writeByte(' ');
    } else if (ascii.isGraph(char)) {
        try writer.writeByte(char);
    } else {
        try writer.writeAll("�");
    }
}
