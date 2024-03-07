// TODO:
// * more tests. Ensure fully working
// * cut down Lexer struct size
//   ✔️ Lexer.ch
//   * Lexer.read_pos
// ✔️ decimal points
// * Number separator (comma, underscore)
// ✔️ Exponent control characters
// * Identifiers
//   ✔️ Subscript control characters
//   * Variables
//     * Single char
//   * Functions
//     * User defined - variables
//     * Builtin - tokens
//   * Programs
//     * Lookahead lexing
//     ✔️ Dynamic list...
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
    read_pos: usize,

    pub fn init(expression: []const u8) Lexer {
        var l: Lexer = .{
            .expr = expression,
            .pos = 0,
            .read_pos = 0,
        };
        l.readChar() catch undefined;
        return l;
    }

    fn peekChar(l: *Lexer) !u8 {
        if (l.read_pos >= l.expr.len) {
            return LexError.EndOfExpression;
        }
        return l.expr[l.read_pos];
    }

    fn readChar(l: *Lexer) !void {
        if (l.read_pos >= l.expr.len) {
            return LexError.EndOfExpression;
        }
        l.pos = l.read_pos;
        l.read_pos += 1;
    }

    fn eatWhitespace(l: *Lexer) void {
        var ch: u8 = l.expr[l.pos];
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
            '`' => tok = newToken(Token.Type.Grave, "`"),
            '~' => tok = newToken(Token.Type.Tilde, "~"),
            '!' => {
                if (l.peekChar() catch 0 == '=') {
                    tok = newToken(Token.Type.CompareNotEqual, "!=");
                } else {
                    tok = newToken(Token.Type.Bang, "!");
                }
            },
            '@' => tok = newToken(Token.Type.At, "@"),
            '#' => tok = newToken(Token.Type.Hashtag, "#"),
            '$' => tok = newToken(Token.Type.Dollar, "$"),
            '%' => tok = newToken(Token.Type.Percent, "%"),
            '^' => tok = newToken(Token.Type.Caret, "^"),
            '&' => tok = newToken(Token.Type.And, "&"),
            '*' => tok = newToken(Token.Type.Asterisk, "*"),
            '(' => tok = newToken(Token.Type.LeftParenthesis, "("),
            ')' => tok = newToken(Token.Type.RightParenthesis, ")"),
            '-' => tok = newToken(Token.Type.Minus, "-"),
            '=' => {
                if (l.peekChar() catch 0 == '=') {
                    l.readChar() catch undefined;
                    tok = newToken(Token.Type.CompareEqual, "==");
                } else {
                    tok = newToken(Token.Type.Equals, "=");
                }
            },
            '+' => tok = newToken(Token.Type.Plus, "+"),
            '[' => tok = newToken(Token.Type.LeftBracket, "["),
            ']' => tok = newToken(Token.Type.RightBracket, "]"),
            '{' => tok = newToken(Token.Type.LeftCurly, "{"),
            '}' => tok = newToken(Token.Type.RightCurly, "}"),
            '|' => tok = newToken(Token.Type.Pipe, "|"),
            ';' => tok = newToken(Token.Type.Semicolon, ";"),
            ':' => tok = newToken(Token.Type.Colon, ":"),
            '\'' => tok = newToken(Token.Type.SingleQuote, "'"),
            '"' => tok = newToken(Token.Type.DoubleQuote, "\""),
            ',' => tok = newToken(Token.Type.Comma, ","),
            '<' => {
                if (l.peekChar() catch 0 == '=') {
                    l.readChar() catch undefined;
                    tok = newToken(Token.Type.CompareLTE, "<=");
                } else {
                    tok = newToken(Token.Type.LeftAngle, "<");
                }
            },
            '>' => {
                if (l.peekChar() catch 0 == '=') {
                    l.readChar() catch undefined;
                    tok = newToken(Token.Type.CompareGTE, ">=");
                } else {
                    tok = newToken(Token.Type.RightAngle, ">");
                }
            },
            '.' => tok = newToken(Token.Type.Period, "."),
            '/' => tok = newToken(Token.Type.Slash, "/"),
            '?' => tok = newToken(Token.Type.Question, "?"),
            17 => tok = newToken(Token.Type.SubscriptStart, "\x11"), // DC1
            18 => tok = newToken(Token.Type.SubscriptEnd, "\x12"), // DC2
            19 => tok = newToken(Token.Type.SuperscriptStart, "\x13"), // DC3
            20 => tok = newToken(Token.Type.SuperscriptEnd, "\x14"), // DC4
            else => {
                if (isAlphabetic(ch)) {
                    tok.type = Token.Type.Identifer;
                    tok.literal = l.readIdentifier();
                    return tok;
                } else if (isNumeric(ch)) {
                    tok.type = Token.Type.Integer;
                    tok.literal = l.readNumber();
                    return tok;
                }
                l.readChar() catch undefined;
                return LexError.InvalidCharacter;
            },
        }

        l.readChar() catch undefined;
        return tok;
    }

    fn readIdentifier(l: *Lexer) []const u8 {
        const start: usize = l.pos;
        var ch: u8 = l.expr[l.pos];
        while (isAlphabetic(ch)) {
            l.readChar() catch break;
            ch = l.expr[l.pos];
        }
        return l.expr[start..l.pos];
    }

    fn readNumber(l: *Lexer) []const u8 {
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
        return l.expr[start..l.pos];
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

fn newToken(tokenType: Token.Type, chs: []const u8) Token {
    return Token{ .type = tokenType, .literal = chs };
}

test "Lexer->Expression 1" {
    const input: []const u8 =
        "let x: u\x11banana\x12 = 13;\n" ++
        "5.8 * x\x137\x14 + 3 == 19;\n" ++
        "fn(x) {\n" ++
        "    return x / 3;\n" ++
        "}";

    const expected = [_]Token{
        newToken(Token.Type.Identifer, "let"),
        newToken(Token.Type.Identifer, "x"),
        newToken(Token.Type.Colon, ":"),
        newToken(Token.Type.Identifer, "u"),
        newToken(Token.Type.SubscriptStart, "\x11"),
        newToken(Token.Type.Identifer, "banana"),
        newToken(Token.Type.SubscriptEnd, "\x12"),
        newToken(Token.Type.Assign, "="),
        newToken(Token.Type.Integer, "13"),
        newToken(Token.Type.Semicolon, ";"),
        newToken(Token.Type.Integer, "5.8"),
        newToken(Token.Type.Asterisk, "*"),
        newToken(Token.Type.Identifer, "x"),
        newToken(Token.Type.SuperscriptStart, "\x13"),
        newToken(Token.Type.Integer, "7"),
        newToken(Token.Type.SuperscriptEnd, "\x14"),
        newToken(Token.Type.Plus, "+"),
        newToken(Token.Type.Integer, "3"),
        newToken(Token.Type.Equals, "=="),
        newToken(Token.Type.Integer, "19"),
        newToken(Token.Type.Semicolon, ";"),
        newToken(Token.Type.Identifer, "fn"),
        newToken(Token.Type.LeftParenthesis, "("),
        newToken(Token.Type.Identifer, "x"),
        newToken(Token.Type.RightParenthesis, ")"),
        newToken(Token.Type.LeftCurly, "{"),
        newToken(Token.Type.Identifer, "return"),
        newToken(Token.Type.Identifer, "x"),
        newToken(Token.Type.Slash, "/"),
        newToken(Token.Type.Integer, "3"),
        newToken(Token.Type.Semicolon, ";"),
        newToken(Token.Type.RightCurly, "}"),
    };

    var l = Lexer.init(input);

    for (expected) |t| {
        const tok: Token = try l.nextToken();

        // std.debug.print(
        //     "\nexpected: <{any}:{s}>  |  got: <{any}:{s}>",
        //     .{
        //         t.type,
        //         t.literal,
        //         tok.type,
        //         tok.literal,
        //     },
        // );
        try std.testing.expectEqual(tok.type, t.type);
        try std.testing.expect(std.mem.eql(u8, tok.literal, t.literal));
    }
}
