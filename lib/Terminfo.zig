const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const os = std.os;
const io = std.io;
const fmt = std.fmt;
const debug = std.debug;

// Workaround for bad libc integration of zigs std.
const constants = if (builtin.link_libc and builtin.os.tag == .linux) os.linux else os.system;

const Terminfo = @This();

const Reader = io.Reader(os.fd_t, os.ReadError, os.read);
fn fd2reader(fd: os.fd_t) Reader {
    return .{ .context = fd };
}

auto_left_margin: bool = false,
auto_right_margin: bool = false,
no_esc_ctlc: bool = false,
ceol_standout_glitch: bool = false,
eat_newline_glitch: bool = false,
erase_overstrike: bool = false,
generic_type: bool = false,
hard_copy: bool = false,
has_meta_key: bool = false,
has_status_line: bool = false,
insert_null_glitch: bool = false,
memory_above: bool = false,
memory_below: bool = false,
move_insert_mode: bool = false,
move_standout_mode: bool = false,
over_strike: bool = false,
status_line_esc_ok: bool = false,
dest_tabs_magic_smso: bool = false,
tilde_glitch: bool = false,
transparent_underline: bool = false,
xon_xoff: bool = false,
needs_xon_xoff: bool = false,
prtr_silent: bool = false,
hard_cursor: bool = false,
non_rev_rmcup: bool = false,
no_pad_char: bool = false,
non_dest_scroll_region: bool = false,
can_change: bool = false,
back_color_erase: bool = false,
hue_lightness_saturation: bool = false,
col_addr_glitch: bool = false,
cr_cancels_micro_mode: bool = false,
has_print_wheel: bool = false,
row_addr_glitch: bool = false,
semi_auto_right_margin: bool = false,
cpi_changes_res: bool = false,
lpi_changes_res: bool = false,

pub fn init() !Terminfo {
    var ret = Terminfo{};

    // Terminfo files for terminals canonically are stored in
    // /usr/share/terminfo/<n>/<name>, where <name> is the name of the terminal
    // and <n> is the first character of the name.
    const name = os.getenv("TERMINAL") orelse blk: {
        const full_name = os.getenv("TERM") orelse return error.UnableToGetTermName;
        var it = mem.split(u8, full_name, "-");
        break :blk it.next() orelse unreachable;
    };

    if (name.len == 0) return error.UnableToGetTermName;

    // TODO make prefix configurable?
    var buffer: [1024]u8 = undefined;
    const path = fmt.bufPrint(&buffer, "/usr/share/terminfo/{c}/{s}", .{ name[0], name }) catch {
        // If the formatting fails it's because the terminals name is
        // unreasonably large.
        return error.InvalidTermName;
    };

    const file = try os.open(path, constants.O.RDONLY, 0);
    defer os.close(file);

    const raw_reader = fd2reader(file);
    var buffered_reader = io.bufferedReader(raw_reader);
    const reader = buffered_reader.reader();

    // The header containst six short integers.
    const magic = try reader.readIntLittle(i16);
    if (magic != 0o433 and magic != 0o435 and magic != 0o1036) {
        return error.InvalidFormat;
    }
    const bytes_term_name = try reader.readIntLittle(i16);
    const bytes_bool_flags = try reader.readIntLittle(i16);
    const shorts_numbers = try reader.readIntLittle(i16);
    const shorts_offsets = try reader.readIntLittle(i16);
    const bytes_string_table = try reader.readIntLittle(i16);

    _ = shorts_numbers;
    _ = shorts_offsets;
    _ = bytes_string_table;

    debug.assert(bytes_term_name >= 0);
    try reader.skipBytes(@intCast(bytes_term_name), .{});

    debug.assert(bytes_bool_flags >= 0);
    for (0..@intCast(bytes_bool_flags)) |i| {
        const b = switch (try reader.readIntLittle(i8)) {
            0 => false,
            1 => true,
            else => return error.InvalidFormat,
        };

        // Order must match that in <term.h>.
        switch (i) {
            0 => ret.auto_left_margin = b,
            1 => ret.auto_right_margin = b,
            2 => ret.no_esc_ctlc = b,
            3 => ret.ceol_standout_glitch = b,
            4 => ret.eat_newline_glitch = b,
            5 => ret.erase_overstrike = b,
            6 => ret.generic_type = b,
            7 => ret.hard_copy = b,
            8 => ret.has_meta_key = b,
            9 => ret.has_status_line = b,
            10 => ret.insert_null_glitch = b,
            11 => ret.memory_above = b,
            12 => ret.memory_below = b,
            13 => ret.move_insert_mode = b,
            14 => ret.move_standout_mode = b,
            15 => ret.over_strike = b,
            16 => ret.status_line_esc_ok = b,
            17 => ret.dest_tabs_magic_smso = b,
            18 => ret.tilde_glitch = b,
            19 => ret.transparent_underline = b,
            20 => ret.xon_xoff = b,
            21 => ret.needs_xon_xoff = b,
            22 => ret.prtr_silent = b,
            23 => ret.hard_cursor = b,
            24 => ret.non_rev_rmcup = b,
            25 => ret.no_pad_char = b,
            26 => ret.non_dest_scroll_region = b,
            27 => ret.can_change = b,
            28 => ret.back_color_erase = b,
            29 => ret.hue_lightness_saturation = b,
            30 => ret.col_addr_glitch = b,
            31 => ret.cr_cancels_micro_mode = b,
            32 => ret.has_print_wheel = b,
            33 => ret.row_addr_glitch = b,
            34 => ret.semi_auto_right_margin = b,
            35 => ret.cpi_changes_res = b,
            36 => ret.lpi_changes_res = b,
            else => unreachable,
        }
    }

    // var i: usize = 0;
    // while (@as(?u8, reader.readByte() catch |err| switch (err) {
    //     error.EndOfStream => null,
    //     else => return err,
    // })) |b| : (i += 1) {
    //     if (i >= bytes_bool_flags) break;
    //     std.debug.print(" >> {c}\n", .{b});
    // }

    // TODO: which values do we actually want?
    //       -> whether we can use unicode characters for UI elements or should use ASCII (scrollbar, mark-prefix (remove config option))
    //       -> whether we can use RGB / 256 colours
    //       -> still the job of the library user to make sure no unsupported colours are used? Makes spoons job simpler

    std.debug.print("{}\n", .{ret});

    return ret;
}
