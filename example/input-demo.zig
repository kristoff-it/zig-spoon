const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const os = std.os;
const unicode = std.unicode;

const spoon = @import("spoon");

var term: spoon.Term = undefined;
var loop: bool = true;
var buf: [32]u8 = undefined;
var read: usize = undefined;
var empty = true;

pub fn main() !void {
    try term.init(render);
    defer term.deinit();

    os.sigaction(os.SIG.WINCH, &os.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = os.empty_sigset,
        .flags = 0,
    }, null);

    var fds: [1]os.pollfd = undefined;
    fds[0] = .{
        .fd = term.tty.handle,
        .events = os.POLL.IN,
        .revents = undefined,
    };

    try term.uncook();
    defer term.cook() catch {};

    try term.hideCursor();

    try term.fetchSize();
    try term.updateContent();

    while (loop) {
        _ = try os.poll(&fds, -1);

        read = try term.readInput(&buf);
        empty = false;
        try term.updateContent();
    }
}

fn render(_: *spoon.Term, _: usize, columns: usize) !void {
    try term.clear();

    try term.moveCursorTo(0, 0);
    try term.setAttribute(.{ .fg = .green, .reverse = true });
    const rest = try term.writeLine(columns, " Spoon example program: input-demo");
    try term.writeByteNTimes(' ', rest);

    try term.moveCursorTo(1, 1);
    try term.setAttribute(.{ .fg = .red, .bold = true });
    _ = try term.writeLine(columns - 1, "Input demo / tester, q to exit.");

    try term.moveCursorTo(3, 1);
    try term.setAttribute(.{ .bold = true });
    if (empty) {
        _ = try term.writeLine(columns - 1, "Press a key! Or try to paste something!");
    } else {
        const writer = term.stdout.writer();
        try writer.writeAll("Bytes read:    ");
        try term.setAttribute(.{});
        try writer.print("{}", .{read});

        var valid_unicode = true;
        _ = unicode.Utf8View.init(buf[0..read]) catch {
            valid_unicode = false;
        };
        try term.moveCursorTo(4, 1);
        try term.setAttribute(.{ .bold = true });
        try writer.writeAll("Valid unicode: ");
        try term.setAttribute(.{});
        if (valid_unicode) {
            try writer.writeAll("yes: \"");
            for (buf[0..read]) |c| {
                switch (c) {
                    127 => try writer.writeAll("^H"),
                    '\x1B' => try writer.writeAll("\\x1B"),
                    '\t' => try writer.writeAll("\\t"),
                    '\n' => try writer.writeAll("\\n"),
                    '\r' => try writer.writeAll("\\r"),
                    'a' & '\x1F' => try writer.writeAll("^a"),
                    'b' & '\x1F' => try writer.writeAll("^b"),
                    'c' & '\x1F' => try writer.writeAll("^c"),
                    'd' & '\x1F' => try writer.writeAll("^d"),
                    'e' & '\x1F' => try writer.writeAll("^e"),
                    'f' & '\x1F' => try writer.writeAll("^f"),
                    'g' & '\x1F' => try writer.writeAll("^g"),
                    'h' & '\x1F' => try writer.writeAll("^h"),
                    'k' & '\x1F' => try writer.writeAll("^k"),
                    'l' & '\x1F' => try writer.writeAll("^l"),
                    'n' & '\x1F' => try writer.writeAll("^n"),
                    'o' & '\x1F' => try writer.writeAll("^o"),
                    'p' & '\x1F' => try writer.writeAll("^p"),
                    'q' & '\x1F' => try writer.writeAll("^q"),
                    'r' & '\x1F' => try writer.writeAll("^r"),
                    's' & '\x1F' => try writer.writeAll("^s"),
                    't' & '\x1F' => try writer.writeAll("^t"),
                    'u' & '\x1F' => try writer.writeAll("^u"),
                    'v' & '\x1F' => try writer.writeAll("^v"),
                    'w' & '\x1F' => try writer.writeAll("^w"),
                    'x' & '\x1F' => try writer.writeAll("^x"),
                    'y' & '\x1F' => try writer.writeAll("^y"),
                    'z' & '\x1F' => try writer.writeAll("^z"),
                    else => try writer.writeByte(c),
                }
            }
            try writer.writeByte('"');
        } else {
            try writer.writeAll("no");
        }

        try term.moveCursorTo(5, 1);
        try term.setAttribute(.{ .bold = true });
        const msg = "Input events:";
        try writer.writeAll(msg);
        var it = spoon.inputParser(buf[0..read]);
        var i: usize = 1;
        try term.setAttribute(.{});
        while (it.next()) |in| : (i += 1) {
            try term.moveCursorTo(5 + (i - 1), msg.len + 3);
            try writer.print("{}: ", .{i});
            switch (in.content) {
                .codepoint => |cp| {
                    if (cp == 'q') {
                        loop = false;
                        return;
                    }
                    try writer.print("codepoint: {} x{X}", .{ cp, cp });
                },
                .function => |f| try writer.print("F{}", .{f}),
                else => try writer.writeAll(@tagName(in.content)),
            }
            if (in.mod_alt) try writer.writeAll(" +Alt");
            if (in.mod_ctrl) try writer.writeAll(" +Ctrl");
        }
    }
}

fn handleSigWinch(_: c_int) callconv(.C) void {
    term.fetchSize() catch {};
    term.updateContent() catch {};
}

/// Custom panic handler, so that we can try to cook the terminal on a crash,
/// as otherwise all messages will be mangled.
pub fn panic(msg: []const u8, trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    term.cook() catch {};
    std.builtin.default_panic(msg, trace);
}
