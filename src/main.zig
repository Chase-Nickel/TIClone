const std = @import("std");
const Token = @import("token.zig").Token;
const lex = @import("lexer.zig");

fn putchar(c: u8) void {
    std.debug.print("{c}", .{c});
}

pub fn main() !void {
    var l = try lex.Lexer.init(
        "+",
    );

    // zig fmt: off
    {var i: usize = 0;
    while (i < 10) : (i += 1) {
        try (try l.consume()).print();
        putchar('\n');
    }
    }
    // zig fmt: on
}
