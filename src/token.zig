const std = @import("std");

pub const Token = struct {
    type: Type,
    start: usize,

    pub const Type = enum {
        LeftParenthesis,
        RightParenthesis,
        Plus,
        Minus,
        Times,
        Divide,
        Number,
        Symbol,
        SubscriptNext,
        SubscriptStart,
        SubscriptEnd,
    };

    pub fn print(token: Token) !void {
        const c: u8 = switch (token.type) {
            .LeftParenthesis => '(',
            .RightParenthesis => ')',
            .Plus => '+',
            .Minus => '-',
            .Times => '*',
            .Divide => '/',
            .Number => 'N',
            .Symbol => 'S',
            .SubscriptNext => '_',
            .SubscriptStart => '{',
            .SubscriptEnd => '}',
        };
        const stdout_file = std.io.getStdOut().writer();
        var bw = std.io.bufferedWriter(stdout_file);
        const stdout = bw.writer();

        try stdout.print(
            "<tok:{}:{u}>",
            .{ token.start, c },
        );

        try bw.flush();
    }
};
