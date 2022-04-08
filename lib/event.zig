// Copyright © 2021 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

pub const Key = union(enum) {
    unknown: void,
    escape: void,
    arrow_up: void,
    arrow_down: void,
    arrow_left: void,
    arrow_right: void,
    end: void,
    home: void,
    page_up: void,
    page_down: void,
    delete: void,
    insert: void,
    function: u8,
    ascii: u8,
};

pub const Event = struct {
    mod_alt: bool = false,
    mod_ctrl: bool = false,
    key: Key,
};
