const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const os = std.os;

const spoon = @import("spoon");

var term: spoon.Term = undefined;
var loop: bool = true;

var cursor: usize = 0;

pub fn main() !void {
    try term.init();
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

    try term.fetchSize();
    try term.setWindowTitle("zig-spoon example: menu", .{});
    try render();

    var buf: [16]u8 = undefined;
    while (loop) {
        _ = try os.poll(&fds, -1);

        const read = try term.readInput(&buf);
        var it = spoon.inputParser(buf[0..read]);
        while (it.next()) |in| {
            switch (in.content) {
                .escape => {
                    loop = false;
                    break;
                },
                .codepoint => |cp| {
                    if (cp == 'q') loop = false;
                    break;
                },
                .arrow_down => {
                    if (cursor < 3) {
                        cursor += 1;
                        try render();
                    }
                },
                .arrow_up => {
                    cursor -|= 1;
                    try render();
                },
                else => {},
            }
        }
    }
}

fn render() !void {
    var rc = try term.getRenderContext();
    defer rc.done() catch {};

    try rc.clear();
    try rc.moveCursorTo(0, 0);
    try rc.setAttribute(.{ .fg = .green, .reverse = true });
    const rest = try rc.writeLine(term.width, " Spoon example program: menu");
    try rc.writeByteNTimes(' ', rest);

    try rc.moveCursorTo(1, 1);
    try rc.setAttribute(.{ .fg = .red, .bold = true });
    _ = try rc.writeLine(term.width - 1, "Up and Down arrows to select, q to exit.");

    try menuEntry(&rc, "foo", 3, term.width);
    try menuEntry(&rc, "bar", 4, term.width);
    try menuEntry(&rc, "baz", 5, term.width);
    try menuEntry(&rc, "xyzzy", 6, term.width);
}

fn menuEntry(rc: *spoon.Term.RenderContext, name: []const u8, row: usize, width: usize) !void {
    try rc.moveCursorTo(row, 2);
    try rc.setAttribute(.{ .fg = .blue, .reverse = (cursor == row - 3) });
    _ = try rc.writeLine(width - 2, name);
}

fn handleSigWinch(_: c_int) callconv(.C) void {
    term.fetchSize() catch {};
    render() catch {};
}

/// Custom panic handler, so that we can try to cook the terminal on a crash,
/// as otherwise all messages will be mangled.
pub fn panic(msg: []const u8, trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);
    term.cook() catch {};
    std.builtin.default_panic(msg, trace);
}
