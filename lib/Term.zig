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
const debug = std.debug;

const log = @import("log.zig");

const Attribute = @import("Attribute.zig");
const spells = @import("spells.zig");
const rpw = @import("restricted_padding_writer.zig");

const Self = @This();

/// Are we in raw or cooked mode?
cooked: bool = true,

/// The original termios configuration saved when entering raw mode.
cooked_termios: os.termios = undefined,

/// Size of the terminal, updated when SIGWINCH is received.
width: usize = undefined,
height: usize = undefined,

/// Are we currently rendering?
currently_rendering: bool = false,

tty: fs.File = undefined,

// TODO options struct
//      -> IO read mode
pub fn init(self: *Self) !void {
    log.debug("initializing Term", .{});
    self.* = .{
        .tty = try fs.cwd().openFile(
            "/dev/tty",
            .{ .read = true, .write = true },
        ),
    };
}

pub fn deinit(self: *Self) void {
    log.debug("de-initializing Term", .{});
    debug.assert(!self.currently_rendering);
    debug.assert(self.cooked);
    self.tty.close();
}

pub fn readInput(self: *Self, buffer: []u8) !usize {
    log.debug("reading input to buffer", .{});
    debug.assert(!self.currently_rendering);
    debug.assert(!self.cooked);
    return try self.tty.read(buffer);
}

/// Enter raw mode.
/// The information on the various flags and escape sequences is pieced
/// together from various sources, including termios(3) and
/// https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html.
/// TODO: IUTF8 ?
pub fn uncook(self: *Self) !void {
    if (!self.cooked) return;
    self.cooked = false;

    log.debug("uncooking terminal", .{});

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

    const writer = self.tty.writer();
    try writer.writeAll(
        spells.save_cursor_position ++
            spells.save_cursor_position ++
            spells.enter_alt_buffer ++
            spells.enable_kitty_keyboard ++
            spells.overwrite_mode ++
            spells.reset_auto_wrap ++
            spells.reset_auto_repeat ++
            spells.reset_auto_interlace ++
            spells.hide_cursor,
    );
}

/// Enter cooked mode.
pub fn cook(self: *Self) !void {
    if (self.cooked) return;
    self.cooked = true;

    log.debug("cooking terminal", .{});

    const writer = self.tty.writer();
    try writer.writeAll(
        spells.disable_kitty_keyboard ++
            spells.clear ++
            spells.leave_alt_buffer ++
            spells.restore_screen ++
            spells.restore_cursor_position ++
            spells.show_cursor ++
            spells.reset_attributes ++
            spells.reset_attributes,
    );

    try os.tcsetattr(self.tty.handle, .FLUSH, self.cooked_termios);
}

pub fn fetchSize(self: *Self) !void {
    if (self.cooked) return;
    log.debug("fetching size", .{});
    var size = mem.zeroes(os.system.winsize);
    const err = os.system.ioctl(self.tty.handle, os.system.T.IOCGWINSZ, @ptrToInt(&size));
    if (os.errno(err) != .SUCCESS) {
        return os.unexpectedErrno(@intToEnum(os.system.E, err));
    }
    self.height = size.ws_row;
    self.width = size.ws_col;
    log.debug("new size: rows={} cols={}", .{ self.height, self.width });
}

/// Set window title using OSC 2. Shall not be called while rendering.
pub fn setWindowTitle(self: *Self, comptime fmt: []const u8, args: anytype) !void {
    debug.assert(!self.currently_rendering);
    log.debug("setting window title: '{s}', {}", .{ fmt, args });
    const writer = self.tty.writer();
    try writer.print("\x1b]2;" ++ fmt ++ "\x1b\\", args);
}

pub fn getRenderContext(self: *Self) !RenderContext {
    log.debug("preparing render context", .{});
    debug.assert(!self.currently_rendering);
    debug.assert(!self.cooked);

    self.currently_rendering = true;
    errdefer self.currently_rendering = false;

    var rc = RenderContext{
        .term = self,
        .buffer = io.bufferedWriter(self.tty.writer()),
    };

    const writer = rc.buffer.writer();
    try writer.writeAll(spells.start_sync);
    try writer.writeAll(spells.reset_attributes);

    return rc;
}

pub const RenderContext = struct {
    term: *Self,
    buffer: io.BufferedWriter(4096, fs.File.Writer),

    /// Finishes the render operation. The render context may not be used any
    /// further.
    pub fn done(rc: *RenderContext) !void {
        debug.assert(rc.term.currently_rendering);
        debug.assert(!rc.term.cooked);
        log.debug("finishing render context", .{});
        defer rc.term.currently_rendering = false;
        const wrtr = rc.buffer.writer();
        try wrtr.writeAll(spells.end_sync);
        try rc.buffer.flush();
    }

    /// Clears all content.
    pub fn clear(rc: *RenderContext) !void {
        debug.assert(rc.term.currently_rendering);
        log.debug("clearing terminal", .{});
        const wrtr = rc.buffer.writer();
        try wrtr.writeAll(spells.clear);
    }

    /// Move the cursor to the specified cell.
    pub fn moveCursorTo(rc: *RenderContext, row: usize, col: usize) !void {
        debug.assert(rc.term.currently_rendering);
        log.debug("moving cursor: row={} col={}", .{ row, col });
        const wrtr = rc.buffer.writer();
        try wrtr.print(spells.move_cursor_fmt, .{ row + 1, col + 1 });
    }

    /// Hide the cursor.
    pub fn hideCursor(rc: *RenderContext) !void {
        debug.assert(rc.term.currently_rendering);
        log.debug("hiding cursor", .{});
        const wrtr = rc.buffer.writer();
        try wrtr.writeAll(spells.hide_cursor);
    }

    /// Show the cursor.
    pub fn showCursor(rc: *RenderContext) !void {
        debug.assert(rc.term.currently_rendering);
        log.debug("showing cursor", .{});
        const wrtr = rc.buffer.writer();
        try wrtr.writeAll(spells.show_cursor);
    }

    /// Set the text attributes for all following writes.
    pub fn setAttribute(rc: *RenderContext, attr: Attribute) !void {
        debug.assert(rc.term.currently_rendering);
        log.debug("setting attribute: {}", .{attr});
        const wrtr = rc.buffer.writer();
        try attr.dump(wrtr);
    }

    pub fn restrictedPaddingWriter(rc: *RenderContext, len: usize) getRestrictedPaddingWriterType() {
        debug.assert(rc.term.currently_rendering);
        log.debug("getting RestrictedPaddingWriter with cell-length {}", .{len});
        return rpw.restrictedPaddingWriter(rc.buffer.writer(), len);
    }

    // TODO there has to be a less annoying way to do this, right?
    fn getRestrictedPaddingWriterType() type {
        var rc: RenderContext = undefined;
        var r = rpw.restrictedPaddingWriter(rc.buffer.writer(), 42);
        return @TypeOf(r);
    }

    /// Write all bytes, wrapping at the end of the line.
    pub fn writeAllWrapping(rc: *RenderContext, bytes: []const u8) !void {
        debug.assert(rc.term.currently_rendering);
        log.debug("writeAllWrapping: \"{s}\"", .{bytes});
        const wrtr = rc.buffer.writer();
        try wrtr.writeAll(spells.enable_auto_wrap);
        try wrtr.writeAll(bytes);
        try wrtr.writeAll(spells.reset_auto_wrap);
    }
};
