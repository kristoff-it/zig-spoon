// Copyright © 2021 - 2022 Leon Henrik Plickat
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

pub const hide_cursor = "\x1B[?25l";
pub const show_cursor = "\x1B[?25h";
pub const move_cursor_fmt = "\x1B[{};{}H";

// https://sw.kovidgoyal.net/kitty/keyboard-protocol/
// This enables an alternative input mode, that makes it possible, among
// others, to unambigously identify the escape key without waiting for
// a timer to run out. And implementing it can be implemented in a backwards
// compatible manner, so that the same code can handle kitty-enabled
// terminals as well as sad terminals.
//
// Must be enabled after entering the alt screen and disabled before leaving
// it.
pub const enable_kitty_keyboard = "\x1B[>1u";
pub const disable_kitty_keyboard = "\x1B[<u";

pub const save_cursor_position = "\x1B[s";
pub const save_screen = "\x1B[?47h";
pub const enter_alt_buffer = "\x1B[?1049h";

pub const leave_alt_buffer = "\x1B[?1049l";
pub const restore_screen = "\x1B[?47l";
pub const restore_cursor_position = "\x1B[u";

pub const clear = "\x1B[2J";

pub const reset_attributes = "\x1B[0m";

pub const overwrite_mode = "\x1B[4l";

// Per https://espterm.github.io/docs/VT100%20escape%20codes.html
pub const enable_auto_wrap = "\x1B[?7h";
pub const reset_auto_wrap = "\x1B[?7l";
pub const reset_auto_repeat = "\x1B[?8l";
pub const reset_auto_interlace = "\x1B[?9l";

pub const start_sync = "\x1BP=1s\x1B\\";
pub const end_sync = "\x1BP=2s\x1B\\";
