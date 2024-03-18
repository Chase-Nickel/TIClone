// TODO:
// * refactor nextToken
//   * switch emits token type
// * more tests. Ensure fully working
// ✔️ cut down Lexer struct size
//   ✔️ Lexer.ch
//   ✔️ Lexer.read_pos
// ✔️ decimal points
// * Number separator (comma, underscore)
// ✔️ Exponent control characters
// * Identifiers
//   ✔️ Subscript control characters
//   * Single char
//     ✔️ Variables
//     * Functions: user defined
//   * Multiple char
//     ✔️ Functions: builtin
//     * Programs
//     ✔️ Lookahead lexing
//     ✔️ Dynamic list...
// * cache token results

const std = @import("std");
const Token = @import("token.zig").Token;
const StringArray = @import("sorted_string_array.zig").SortedStringArray;

pub const LexError = error{
    EndOfExpression,
    InvalidCharacter,
};

pub const Lexer = struct {
    expr: []const u8,
    pos: usize,
    keywords: StringArray(16, .LongestToShortest),

    pub fn init(expression: []const u8, kwords: StringArray(16, .LongestToShortest)) Lexer {
        const l: Lexer = .{
            .expr = expression,
            .pos = 0,
            .keywords = kwords,
        };
        return l;
    }

    fn peekChar(l: *Lexer) !u8 {
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
        var tok: Token = undefined;

        if (l.pos >= l.expr.len) {
            return LexError.EndOfExpression;
        }

        l.eatWhitespace();

        const ch: u8 = l.expr[l.pos];
        switch (ch) {
            '`' => tok = newToken(.Grave, "`"),
            '~' => tok = newToken(.Tilde, "~"),
            '!' => {
                if (l.peekChar() catch 0 == '=') {
                    l.readChar() catch unreachable;
                    tok = newToken(.CompareNotEquals, "!=");
                } else {
                    tok = newToken(.Bang, "!");
                }
            },
            '@' => tok = newToken(.At, "@"),
            '#' => tok = newToken(.Hashtag, "#"),
            '$' => tok = newToken(.Dollar, "$"),
            '%' => tok = newToken(.Percent, "%"),
            '^' => tok = newToken(.Caret, "^"),
            '&' => tok = newToken(.And, "&"),
            '*' => tok = newToken(.Asterisk, "*"),
            '(' => tok = newToken(.LeftParenthesis, l.expr[l.pos .. l.pos + 1]),
            ')' => tok = newToken(.RightParenthesis, ")"),
            '-' => tok = newToken(.Minus, "-"),
            '=' => {
                if (l.peekChar() catch 0 == '=') {
                    l.readChar() catch unreachable;
                    tok = newToken(.CompareEquals, "==");
                } else {
                    tok = newToken(.Equals, "=");
                }
            },
            '+' => tok = newToken(.Plus, "+"),
            '[' => tok = newToken(.LeftBracket, "["),
            ']' => tok = newToken(.RightBracket, "]"),
            '{' => tok = newToken(.LeftCurly, "{"),
            '}' => tok = newToken(.RightCurly, "}"),
            '|' => tok = newToken(.Pipe, "|"),
            ';' => tok = newToken(.Semicolon, ";"),
            ':' => tok = newToken(.Colon, ":"),
            '\'' => tok = newToken(.SingleQuote, "'"),
            '"' => tok = newToken(.DoubleQuote, "\""),
            ',' => tok = newToken(.Comma, ","),
            '<' => {
                if (l.peekChar() catch 0 == '=') {
                    l.readChar() catch unreachable;
                    tok = newToken(.CompareLTE, "<=");
                } else {
                    tok = newToken(.LeftAngle, "<");
                }
            },
            '>' => {
                if (l.peekChar() catch 0 == '=') {
                    l.readChar() catch unreachable;
                    tok = newToken(.CompareGTE, ">=");
                } else {
                    tok = newToken(.RightAngle, ">");
                }
            },
            '.' => tok = newToken(.Period, "."),
            '/' => tok = newToken(.Slash, "/"),
            '?' => tok = newToken(.Question, "?"),
            17 => tok = newToken(.SubscriptStart, "\x11"), // DC1
            18 => tok = newToken(.SubscriptEnd, "\x12"), // DC2
            19 => tok = newToken(.SuperscriptStart, "\x13"), // DC3
            20 => tok = newToken(.SuperscriptEnd, "\x14"), // DC4
            else => {
                if (isAlphabetic(ch)) {
                    return l.readIdentifier();
                } else if (isNumeric(ch)) {
                    return l.readNumber();
                }
                l.readChar() catch undefined;
                return LexError.InvalidCharacter;
            },
        }

        l.readChar() catch undefined;
        return tok;
    }

    fn readIdentifier(l: *Lexer) Token {
        const start: usize = l.pos;
        var ch: u8 = l.expr[l.pos];
        while (isAlphabetic(ch)) {
            l.readChar() catch break;
            ch = l.expr[l.pos];
        }
        const str: []const u8 = l.expr[start..l.pos];
        for (l.keywords.asSlice()) |kword| {
            if (std.mem.startsWith(u8, str, kword)) {
                l.pos = start + kword.len;
                return Token{
                    .literal = l.expr[start .. start + kword.len],
                    .type = .Identifier,
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
        while (isNumeric(ch)) {
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
};

fn isAlphabetic(ch: u8) bool {
    return ('a' <= ch and ch <= 'z') or
        ('A' <= ch and ch <= 'Z') or
        (ch == '_');
}

fn isNumeric(ch: u8) bool {
    return ('0' <= ch and ch <= '9') or ch == '.';
}

fn newToken(token_type: Token.Type, literal: []const u8) Token {
    return Token{ .type = token_type, .literal = literal };
}

test "Lexer>Expression-1" {
    const input: []const u8 =
        "let x: u\x11lab\x12 = 13;\n" ++
        "5.8 * x\x137\x14 + 3 == 19;\n" ++
        "fn(x) {\n" ++
        "    return x / 3;\n" ++
        "}";

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
    };

    var s = StringArray(16, .LongestToShortest){};
    try s.insert("return");
    try s.insert("fn");
    try s.insert("let");
    var l = Lexer.init(input, s);

    std.debug.print("\n", .{});
    for (expected) |t| {
        const tok: Token = try l.nextToken();

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
