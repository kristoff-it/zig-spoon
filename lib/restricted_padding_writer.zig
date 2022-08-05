// Copyright © 2022 Leon Henrik Plickat
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

const CodepointStagingArea = struct {
    const Self = @This();

    len: usize,
    left: usize,
    buf: [4]u8 = undefined,

    pub fn new(first_byte: u8, len: usize) Self {
        var ret = Self{
            .len = len,
            .left = len - 1,
        };
        ret.buf[0] = first_byte;
        return ret;
    }

    pub fn addByte(self: *Self, b: u8) bool {
        debug.assert(self.left > 0);
        self.buf[self.len - self.left] = b;
        self.left -= 1;
        return self.left == 0;
    }

    pub fn bytes(self: *Self) []const u8 {
        return self.buf[0..self.len];
    }
};

/// A writer that writes at most N terminal cells. If the caller tries to write
/// more, "…" is written and the remaining bytes will be silently discarded.
/// Can optionally pad the remaining size with whitespace or return it.
/// Needs to be finished with either pad(), getRemaining() or finish() to
/// function correctly.
///
/// TODO graphemes, emoji, double wide characters and similar pain :(
pub fn RestrictedPaddingWriter(comptime UnderlyingWriter: type) type {
    return struct {
        const Self = @This();

        pub const WriteError = UnderlyingWriter.Error;
        pub const Writer = std.io.Writer(*Self, WriteError, write);

        underlying_writer: UnderlyingWriter,

        // This counts terminal cells, not bytes or codepoints!
        // TODO ok, right now it does count codepoints, see previous TODO comment...
        len_left: usize,

        codepoint_staging_area: ?CodepointStagingArea = null,
        codepoint_holding_area: ?CodepointStagingArea = null,

        pub fn finish(self: *Self) !void {
            // TODO what should happen if the codepoint in the holding area is
            //      incomplete or bad?
            if (self.codepoint_holding_area) |_| {
                try self.underlying_writer.writeAll(self.codepoint_holding_area.?.bytes());
                self.codepoint_holding_area = null;
                self.len_left -= 1;
            }
        }

        pub fn pad(self: *Self) !void {
            try self.finish();
            try self.underlying_writer.writeByteNTimes(' ', self.len_left);
            self.len_left = 0;
        }

        pub fn getRemaining(self: *Self) !usize {
            try self.finish();
            return self.len_left;
        }

        pub fn writer(self: *Self) Writer {
            return .{ .context = self };
        }

        pub fn write(self: *Self, bytes: []const u8) WriteError!usize {
            if (self.codepoint_holding_area) |_| {
                debug.assert(self.len_left == 1);
                self.codepoint_holding_area = null;
                self.len_left = 0;
                try self.underlying_writer.writeAll("…");
                return bytes.len;
            }

            if (self.len_left == 0) {
                return bytes.len;
            }

            for (bytes) |c, i| {
                if (self.len_left == 0) break;

                if (self.codepoint_staging_area) |_| {
                    if (self.codepoint_staging_area.?.addByte(c)) {
                        try self.maybeWriteCodepointStagingArea(bytes.len - i - 1);
                    }
                } else {
                    const utf8len = unicode.utf8ByteSequenceLength(c) catch {
                        try self.maybeWriteByte('?', bytes.len - i - 1);
                        continue;
                    };
                    if (utf8len == 1) {
                        try self.maybeWriteByte(c, bytes.len - i - 1);
                    } else {
                        self.codepoint_staging_area = CodepointStagingArea.new(c, utf8len);
                    }
                }
            }

            return bytes.len;
        }

        fn maybeWriteCodepointStagingArea(self: *Self, remaining_bytes_len: usize) !void {
            debug.assert(self.len_left > 0);
            if (self.len_left > 1) {
                try self.underlying_writer.writeAll(self.codepoint_staging_area.?.bytes());
                self.codepoint_staging_area = null;
                self.len_left -= 1;
            } else {
                if (remaining_bytes_len > 0) {
                    try self.underlying_writer.writeAll("…");
                    self.codepoint_staging_area = null;
                    self.len_left -= 1;
                } else {
                    self.codepoint_holding_area = self.codepoint_staging_area;
                    self.codepoint_staging_area = null;
                }
            }
        }

        fn maybeWriteByte(self: *Self, b: u8, remaining_bytes_len: usize) !void {
            debug.assert(self.len_left > 0);
            const byte = if (b == '\n' or b == '\t' or b == '\r' or b == ' ') ' ' else b;
            if (self.len_left > 1) {
                try self.underlying_writer.writeByte(byte);
                self.len_left -= 1;
            } else {
                if (remaining_bytes_len > 0) {
                    try self.underlying_writer.writeAll("…");
                    self.len_left -= 1;
                } else {
                    self.codepoint_holding_area = CodepointStagingArea.new(byte, 1);
                }
            }
        }
    };
}

pub fn restrictedPaddingWriter(underlying_stream: anytype, len: usize) RestrictedPaddingWriter(@TypeOf(underlying_stream)) {
    return .{
        .underlying_writer = underlying_stream,
        .len_left = len,
    };
}
