const std = @import("std");

pub const Token = struct {
    type: Type,
    literal: []const u8,

    pub const Type = enum {
        Identifer,
        Integer,

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
        Assign,
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

        Equals,
        NotEquals,
        LTE,
        GTE,

        SubscriptStart,
        SubscriptEnd,
        SuperscriptStart,
        SuperscriptEnd,
    };
};
