// TODO:
// * more tests. Ensure fully working
// * Number separator (comma, underscore)
// * Identifiers
//   * Multiple char
//     * Programs
// * cache token results

const std = @import("std");
const Token = @import("token.zig").Token;

pub const LexError = error{
    EndOfExpression,
    InvalidCharacter,
};

pub const Lexer = struct {
    expr: []const u8,
    pos: usize,

    const Keyword = struct { name: []const u8, type: Token.Type };
    pub var keywords = [_]Keyword{
        .{ .name = "return", .type = .Identifier },
        .{ .name = "let", .type = .Identifier },
        .{ .name = "fn", .type = .Identifier },
        .{ .name = "sin", .type = .Function },
        .{ .name = "csc", .type = .Function },
        .{ .name = "arcsin", .type = .Function },
        .{ .name = "arccsc", .type = .Function },
        .{ .name = "cos", .type = .Function },
        .{ .name = "sec", .type = .Function },
        .{ .name = "arccos", .type = .Function },
        .{ .name = "arcsec", .type = .Function },
        .{ .name = "tan", .type = .Function },
        .{ .name = "cot", .type = .Function },
        .{ .name = "arctan", .type = .Function },
        .{ .name = "arccot", .type = .Function },
        .{ .name = "returned", .type = .Identifier },
    };

    fn sortKeywords() void {
        std.sort.block(Keyword, &keywords, {}, struct {
            fn greaterName(context: void, lhs: Keyword, rhs: Keyword) bool {
                _ = context;
                return lhs.name.len > rhs.name.len;
            }
        }.greaterName);
    }

    pub fn init(expression: []const u8) Lexer {
        const l: Lexer = .{
            .expr = expression,
            .pos = 0,
        };
        sortKeywords();
        return l;
    }

    fn peekChar(l: Lexer) LexError!u8 {
        if (l.pos + 1 >= l.expr.len) {
            return LexError.EndOfExpression;
        }
        return l.expr[l.pos + 1];
    }

    fn readChar(l: *Lexer) !void {
        if (l.pos + 1 >= l.expr.len) {
            return LexError.EndOfExpression;
        }
        l.pos += 1;
    }

    fn eatWhitespace(l: *Lexer) void {
        var ch = l.expr[l.pos];
        while (ch == ' ' or ch == '\n' or ch == '\t' or ch == '\r') {
            l.readChar() catch break;
            ch = l.expr[l.pos];
        }
    }

    pub fn nextToken(l: *Lexer) !Token {
        if (l.pos >= l.expr.len) {
            return LexError.EndOfExpression;
        }

        l.eatWhitespace();

        const ch: u8 = l.expr[l.pos];
        const token_type = switch (ch) {
            '`' => .Grave,
            '~' => .Tilde,
            '!' => l.checkCompareToken(ch),
            '@' => .At,
            '#' => .Hashtag,
            '$' => .Dollar,
            '%' => .Percent,
            '^' => .Caret,
            '&' => .And,
            '*' => .Asterisk,
            '(' => .LeftParenthesis,
            ')' => .RightParenthesis,
            '-' => .Minus,
            '=' => l.checkCompareToken(ch),
            '+' => .Plus,
            '[' => .LeftBracket,
            ']' => .RightBracket,
            '{' => .LeftCurly,
            '}' => .RightCurly,
            '|' => .Pipe,
            ';' => .Semicolon,
            ':' => .Colon,
            '\'' => .SingleQuote,
            '"' => .DoubleQuote,
            ',' => .Comma,
            '<' => l.checkCompareToken(ch),
            '>' => l.checkCompareToken(ch),
            '/' => .Slash,
            '?' => .Question,
            17 => .SubscriptStart, // DC1
            18 => .SubscriptEnd, // DC2
            19 => .SuperscriptStart, // DC3
            20 => .SuperscriptEnd, // DC4
            'a'...'z', 'A'...'Z' => .Identifier,
            '0'...'9', '.' => .Number,
            else => {
                l.readChar() catch undefined;
                return LexError.InvalidCharacter;
            },
        };

        switch (token_type) {
            .Identifier => return l.readIdentifier(),
            .Number => return l.readNumber(),
            .CompareLTE, .CompareGTE, .CompareEquals, .CompareNotEquals => {
                defer {
                    l.readChar() catch undefined;
                    l.readChar() catch undefined;
                }
                return Token{ .type = token_type, .literal = l.expr[l.pos .. l.pos + 2] };
            },
            else => {
                defer l.readChar() catch undefined;
                return Token{ .type = token_type, .literal = l.expr[l.pos .. l.pos + 1] };
            },
        }
    }

    fn readIdentifier(l: *Lexer) Token {
        const start: usize = l.pos;
        var ch: u8 = l.expr[l.pos];
        while (std.ascii.isAlphabetic(ch) or ch == '_') {
            l.readChar() catch break;
            ch = l.expr[l.pos];
        }
        const str: []const u8 = l.expr[start..l.pos];
        for (keywords) |kword| {
            if (std.mem.startsWith(u8, str, kword.name)) {
                l.pos = start + kword.name.len;
                return Token{
                    .literal = kword.name,
                    .type = kword.type,
                };
            }
        }
        l.pos = start + 1;
        return Token{
            .literal = l.expr[start..l.pos],
            .type = .Identifier,
        };
    }

    fn readNumber(l: *Lexer) Token {
        const start: usize = l.pos;
        var has_dec: bool = false;
        var ch: u8 = l.expr[l.pos];
        while (std.ascii.isDigit(ch) or ch == '.') {
            if (ch == '.') {
                if (has_dec) break;
                has_dec = true;
            }

            l.readChar() catch break;
            ch = l.expr[l.pos];
        }
        return Token{
            .literal = l.expr[start..l.pos],
            .type = .Number,
        };
    }

    fn checkCompareToken(l: Lexer, ch: u8) Token.Type {
        const is_comparison = l.peekChar() catch 0 == '=';
        return switch (ch) {
            '=' => if (is_comparison) .CompareEquals else .Equals,
            '!' => if (is_comparison) .CompareNotEquals else .Bang,
            '<' => if (is_comparison) .CompareLTE else .LeftAngle,
            '>' => if (is_comparison) .CompareGTE else .RightAngle,
            else => unreachable,
        };
    }
};

fn newToken(token_type: Token.Type, literal: []const u8) Token {
    return Token{ .type = token_type, .literal = literal };
}

const print_debug = true;

test "Lexer>Expression-1" {
    const input: []const u8 =
        "let x: u\x11lab\x12 = 13;\n" ++
        "5.8 * x\x137\x14 + 3 == 19;\n" ++
        "fn(x) {\n" ++
        "    return x / 3;\n" ++
        "}\n" ++
        "returned + 9;";

    const expected = [_]Token{
        newToken(.Identifier, "let"),
        newToken(.Identifier, "x"),
        newToken(.Colon, ":"),
        newToken(.Identifier, "u"),
        newToken(.SubscriptStart, "\x11"),
        newToken(.Identifier, "l"),
        newToken(.Identifier, "a"),
        newToken(.Identifier, "b"),
        newToken(.SubscriptEnd, "\x12"),
        newToken(.Equals, "="),
        newToken(.Number, "13"),
        newToken(.Semicolon, ";"),
        newToken(.Number, "5.8"),
        newToken(.Asterisk, "*"),
        newToken(.Identifier, "x"),
        newToken(.SuperscriptStart, "\x13"),
        newToken(.Number, "7"),
        newToken(.SuperscriptEnd, "\x14"),
        newToken(.Plus, "+"),
        newToken(.Number, "3"),
        newToken(.CompareEquals, "=="),
        newToken(.Number, "19"),
        newToken(.Semicolon, ";"),
        newToken(.Identifier, "fn"),
        newToken(.LeftParenthesis, "("),
        newToken(.Identifier, "x"),
        newToken(.RightParenthesis, ")"),
        newToken(.LeftCurly, "{"),
        newToken(.Identifier, "return"),
        newToken(.Identifier, "x"),
        newToken(.Slash, "/"),
        newToken(.Number, "3"),
        newToken(.Semicolon, ";"),
        newToken(.RightCurly, "}"),
        newToken(.Identifier, "returned"),
        newToken(.Plus, "+"),
        newToken(.Number, "9"),
        newToken(.Semicolon, ";"),
    };

    var l = Lexer.init(input);

    std.debug.print("\n", .{});
    for (expected) |t| {
        const tok: Token = try l.nextToken();

        if (print_debug)
            std.debug.print(
                "expected: <{any}:{s}>  |  got: <{any}:{s}>\n",
                .{
                    t.type,
                    t.literal,
                    tok.type,
                    tok.literal,
                },
            );
        try std.testing.expectEqual(tok.type, t.type);
        try std.testing.expect(std.mem.eql(u8, tok.literal, t.literal));
    }
    std.debug.print("\n", .{});
}
