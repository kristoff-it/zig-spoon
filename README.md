# zig-spoon

zig-spoon is a zig library offering a simple, low-level and allocation free
abstraction for creating TUI programs. zig-spoon takes care of wrangling the
terminal, but unlike other TUI libraries it does not get in the way when you
want to render the interface.

zig-spoon supports the kitty keyboard protocol.

```
    _
  /   \
 |     |
  \   /
   | |
   | |
   | |
   | |
   (_)
```


## Documentation
### General Usage

`import.zig` is the entry point of zig-spoon and the file you should import into
your project. The rest of this document assumes you imported it as `spoon`.

To start your TUI, you need to have a mutable instance of `spoon.Term` and
initialize it.

```zig
var term: spoon.Term = undefined;
try term.init(render);
defer term.deinit();
```

`render` is a pointer to a function like this:

```zig
fn render(term: *spoon.Term, rows: usize, columns: usize) !void {
    // ...
}
```

In this function you can put the code to render the user interface. zig-spoon
provides helper functions for this, which are described at the end of this
section. Note that *you* need to keep track of what needs to be (re-)drawn.
zig-spoon will not automatically clear the previous terminal contents.

Before drawing the UI, you need to put the terminal into raw mode ("uncook"-ing
it). Among other things, this will enter the alt screen and messes with a few
terminal settings.

```zig
try term.uncook();
defer term.cook() catch {};
```

Now update the terminal size and contents, which will call your render function
for the first time.

```zig
try term.fetchSize();
try term.updateContent();
```

Call these two functions in that order whenever you expect the terminal size may
have changed, for example when receiving `SIGWINCH`. If you want to update the
contents of the UI, call just `Term.updateContent()`.

To integrate zig-spoon into your event-loop, you can poll the TTY handle, which
you can access via `term.tty.handle`.

When the file descriptor is readiable, you can easiely access all UI events.

```zig
while (try term.nextEvent()) |ev| {
    // ...
}
```


### Drawing Functions

The following functions can be used inside your render function for drawing the
user interface.

```zig
/// Clears all content.
pub fn clear(self: *Term) !void { }

/// Move the cursor to the specified cell.
pub fn moveCursorTo(self: *Term, row: usize, col: usize) !void { }

/// Hide the cursor.
pub fn hideCursor(self: *Term) !void { }

/// Show the cursor.
pub fn showCursor(self: *Term) !void { }

/// Set the text attributes for all following writes.
pub fn setAttribute(self: *Term, attr: Attribute) !void { }

/// Write a byte N times.
pub fn writeByteNTimes(self: *Term, byte: u8, n: usize) !void { }

/// Write at most `width` of `bytes`, abbreviating with '…' if necessary. If the
/// amount of written codepoints is less than `width`, returns the difference,
/// otherwise 0.
pub fn writeLine(self: *Term, width: usize, bytes: []const u8) !usize { }
```


## License

zig-spoon is licensed under version 2.0 of the MPL.

The code of the exmaple programs in `example/` are released into the public
domain.

