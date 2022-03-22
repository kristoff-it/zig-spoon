const Term = @import("Term.zig");

pub const UserRender = fn (self: *Term, rows: usize, columns: usize) anyerror!void;
