const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const os = std.os;

const spoon = @import("spoon");

var term: spoon.Term = undefined;
var last_event: spoon.Event = .{ .key = .unknown };
var loop: bool = true;

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
    const rest = try term.writeLine(columns, " Spoon example program: keyprint");
    try term.writeByteNTimes(' ', rest);

    try term.moveCursorTo(1, 1);
    try term.setAttribute(.{ .fg = .red, .bold = true });
    _ = try term.writeLine(columns - 1, "Key and modifier demo/tester, q to exit.");

    try term.moveCursorTo(3, 3);
    try term.setAttribute(.{ .bold = true });
    try term.writeAll("      key: ");
    try term.setAttribute(.{});
    if (last_event.key == .ascii) {
        switch (last_event.key.ascii) {
            127 => try term.writeAll("backspace"),
            '\n' => try term.writeAll("enter"),
            '\t' => try term.writeAll("tab"),
            else => {
                try term.writeByte('\'');
                try term.writeByte(last_event.key.ascii);
                try term.writeByte('\'');
            },
        }
    } else {
        try term.writeAll(@tagName(last_event.key));
    }

    try term.moveCursorTo(4, 3);
    try term.setAttribute(.{ .bold = true });
    try term.writeAll("modifiers: ");
    try term.setAttribute(.{});
    if (last_event.mod_alt) try term.writeAll("alt ");
    if (last_event.mod_ctrl) try term.writeAll("ctrl");
}

fn handleUiEvents() !void {
    while (loop) {
        if (try term.nextEvent()) |ev| {
            last_event = ev;
            if (ev.key == .ascii and ev.key.ascii == 'q') {
                loop = false;
                return;
            }
        } else {
            break;
        }
        try term.updateContent();
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
