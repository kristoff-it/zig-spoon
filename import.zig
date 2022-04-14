// Copyright © 2022 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

pub const version = "0.1.0";

pub const spells = @import("lib/spells.zig");

pub const Attribute = @import("lib/Attribute.zig");
pub const Term = @import("lib/Term.zig");
pub const inputParser = @import("lib/input.zig").inputParser;
pub const Input = @import("lib/input.zig").Input;
pub const InputContent = @import("lib/input.zig").InputContent;
