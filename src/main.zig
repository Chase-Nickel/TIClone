const std = @import("std");
const Token = @import("token.zig").Token;
const lex = @import("lexer.zig");

pub fn main() !void {
    std.debug.print("I like chicken\n", .{});
}
