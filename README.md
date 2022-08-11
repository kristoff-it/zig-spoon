# zig-spoon

zig-spoon is a zig library offering a simple, low-level and allocation free
abstraction for creating TUI programs. zig-spoon takes care of wrangling the
terminal, but unlike other TUI libraries it does not get in the way when you
want to render the interface.

zig-spoon supports the kitty keyboard protocol.

The text attribute code can be used independently, so zig-spoon is also useful
for non-TUI terminal programs that still want fancy text.

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


## License

zig-spoon is licensed under the GPL version 3 (no later).

Yes, that means that any project using zig-spoon - although not necessarily
all code - will also be licensed under the GPLv3. This should not be a problem
for any honest FOSS project.

While I recognize that licensing a  library under the GPL is unusual and poses
restrictions on users of the library, I consider this choice necessary to ensure
that all my code always remains Free Software and therefore always remains of
most use to end users. I write software for people, not for companies. As such,
I do not wish any of it being used as free labour for some proprietary project
by a company wanting to improve their profit margins.
Thank you for understanding.
