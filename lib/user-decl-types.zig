// Copyright © 2022 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const Term = @import("Term.zig");

pub const UserRender = fn (self: *Term, rows: usize, columns: usize) anyerror!void;
