const std = @import("std");

pub const Token = struct {
    type: Type,
    literal: []const u8,

    pub const Type = enum {
        Identifier,
        Function,
        Program,
        Number,

        Grave,
        Tilde,
        Bang,
        At,
        Hashtag,
        Dollar,
        Percent,
        Caret,
        And,
        Asterisk,
        LeftParenthesis,
        RightParenthesis,
        Minus,
        Equals,
        Plus,
        LeftBracket,
        RightBracket,
        LeftCurly,
        RightCurly,
        Pipe,
        Semicolon,
        Colon,
        SingleQuote,
        DoubleQuote,
        Comma,
        Period,
        LeftAngle,
        RightAngle,
        Slash,
        Question,
        CompareEquals,
        CompareNotEquals,
        CompareLTE,
        CompareGTE,
        SubscriptStart,
        SubscriptEnd,
        SuperscriptStart,
        SuperscriptEnd,
    };
};
