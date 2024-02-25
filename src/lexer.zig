const std = @import("std");
const Token = @import("token.zig").Token;

pub const LexError = error{
    EndOfExpression,
    InvalidSyntax,
};

pub const Lexer = struct {
    expression: []const u8,
    index: usize = 0,
    front: ?Token = null,
    next: ?Token = null,

    /// \brief: Initialize a new lexer
    /// @arg expression: expression that
    ///                  the lexer is lex
    /// @return New lexer object or an
    ///         InvalidSyntax error
    pub fn init(expression: []const u8) LexError!Lexer {
        var lexer: Lexer = .{
            .expression = expression,
        };

        if (lexer.peekCurrentChar() != null)
            try lexer.constructNextToken();

        lexer.front = lexer.next;
        if (lexer.peekCurrentChar() != null)
            try lexer.constructNextToken();

        return lexer;
    }

    /// \brief: Returns if a lexer is at
    ///         the end of the expression or not
    ///  @arg lexer: Lexer object to act on
    ///  @return Whether the lexer has exhausted
    ///          the expression or not
    pub fn atEnd(lexer: Lexer) bool {
        return lexer.index >= lexer.expression.len;
    }

    /// \brief: Peek at the current token
    /// @arg lexer: Lexer from which
    ///             the token is taken
    /// @return EndOfExpression error or
    ///         the lexer's current token
    pub fn peekCurrent(lexer: Lexer) LexError!Token {
        if (lexer.front) |token| {
            return token;
        }
        return LexError.EndOfExpression;
    }

    /// \brief: Peek at the next token
    /// @arg lexer: Lexer from which
    ///             the token is taken
    /// @return LexError or the
    ///         lexer's next token
    pub fn peekNext(lexer: Lexer) LexError!Token {
        if (lexer.next) |token| {
            return token;
        }
        return LexError.EndOfExpression;
    }

    /// \brief: Return the front token and
    ///         then move the lexer forward
    ///         in the expression
    /// @arg lexer: Lexer to act on
    /// @return LexError or the lexer's front
    ///         token before advancing
    pub fn consume(lexer: *Lexer) LexError!Token {
        const res: ?Token = lexer.front;

        lexer.front = lexer.next;
        if (lexer.peekCurrentChar() != null)
            try lexer.constructNextToken();

        if (res) |token| {
            return token;
        }
        return LexError.EndOfExpression;
    }

    fn constructNextToken(lexer: *Lexer) LexError!void {
        const start: usize = lexer.index;
        var token_type: Token.Type = undefined;

        token_type = try lexer.matchSingleChar() orelse
            try lexer.matchMultipleChar();

        lexer.next = Token{
            .type = token_type,
            .start = start,
        };
    }

    fn matchSingleChar(lexer: *Lexer) LexError!?Token.Type {
        var c: u8 = undefined;
        if (lexer.peekCurrentChar()) |char| {
            c = char;
        } else {
            return LexError.EndOfExpression;
        }
        lexer.index += 1;

        return switch (c) {
            '(' => .LeftParenthesis,
            ')' => .RightParenthesis,
            '+' => .Plus,
            '-' => .Minus,
            '*' => .Times,
            '/' => .Divide,
            'A'...'Z', 'a'...'z' => .Symbol,
            else => null,
        };
    }

    fn matchMultipleChar(lexer: *Lexer) LexError!Token.Type {
        var c: u8 = undefined;
        if (lexer.peekCurrentChar()) |char| {
            c = char;
        } else {
            return LexError.EndOfExpression;
        }
        lexer.index += 1;

        switch (c) {
            '_' => {
                c = lexer.peekNextChar() orelse ' ';
                if (c == '{')
                    return Token.Type.SubscriptStart;
                return Token.Type.SubscriptNext;
            },
            '0'...'9', '.' => {
                var has_dec: bool = false;
                while (std.ascii.isDigit(c) or c == '.') {
                    if (c == '.') {
                        if (has_dec)
                            return LexError.InvalidSyntax;
                        has_dec = true;
                    }
                    lexer.index += 1;
                    c = lexer.peekCurrentChar() orelse break;
                }
                return Token.Type.Number;
            },
            else => return LexError.InvalidSyntax,
        }
    }

    fn peekCurrentChar(lexer: Lexer) ?u8 {
        if (lexer.atEnd())
            return null;
        return lexer.expression[lexer.index];
    }

    fn peekNextChar(lexer: Lexer) ?u8 {
        if (lexer.index + 1 >= lexer.expression.len)
            return null;
        return lexer.expression[lexer.index + 1];
    }
};
