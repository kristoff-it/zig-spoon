// Copyright © 2022 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");

pub fn debug(comptime format: []const u8, args: anytype) void {
    const root = @import("root");
    if (@hasDecl(root, "spoon_log") and root.spoon_log) {
        const log = std.log.scoped(.spoon);
        log.debug(format, args);
    }
}
