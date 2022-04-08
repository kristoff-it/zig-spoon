const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const os = std.os;

const spoon = @import("spoon");

var term: spoon.Term = undefined;
var loop: bool = true;

var cursor: usize = 0;

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
        try handleUiEvents();
    }
}

fn render(_: *spoon.Term, _: usize, columns: usize) !void {
    try term.clear();

    try term.moveCursorTo(0, 0);
    try term.setAttribute(.{ .fg = .green, .reverse = true });
    const rest = try term.writeLine(columns, " Spoon example program: menu");
    try term.writeByteNTimes(' ', rest);

    try term.moveCursorTo(1, 1);
    try term.setAttribute(.{ .fg = .red, .bold = true });
    _ = try term.writeLine(columns - 1, "Up and Down arrows to select, q to exit.");

    try menuEntry("foo", 3, columns);
    try menuEntry("bar", 4, columns);
    try menuEntry("baz", 5, columns);
    try menuEntry("xyzzy", 6, columns);
}

fn menuEntry(name: []const u8, row: usize, width: usize) !void {
    try term.moveCursorTo(row, 2);
    try term.setAttribute(.{ .fg = .blue, .reverse = (cursor == row - 3) });
    _ = try term.writeLine(width - 2, name);
}

fn handleUiEvents() !void {
    while (loop) {
        if (try term.nextEvent()) |ev| {
            switch (ev.key) {
                .escape => {
                    loop = false;
                    return;
                },
                .ascii => |key| {
                    if (key == 'q') {
                        loop = false;
                        return;
                    }
                },
                .arrow_down => {
                    if (cursor < 3) {
                        cursor += 1;
                        try term.updateContent();
                    }
                },
                .arrow_up => {
                    cursor -|= 1;
                    try term.updateContent();
                },
                else => {},
            }
        } else {
            break;
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
