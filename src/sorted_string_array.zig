const std = @import("std");

const Direction = enum {
    Left,
    Right,
    Center,
};

/// Sorted Array of []u8
/// Greatest length to shortest
pub fn SortedStringArray(comptime length: usize, comptime comparison: Direction) type {
    if (comparison != .Left and comparison != .Right) {
        @compileError(
            \\Comparison direction must be either:
            \\  .Left  for least to greatest
            \\  .Right for greatest to least
        );
    }

    return struct {
        const Self = @This();

        buf: [length][]const u8 = undefined,
        len: usize = 0,

        fn compare(left: []const u8, right: []const u8) bool {
            if (comparison == .Left)
                return left.len < right.len;
            if (comparison == .Right)
                return left.len > right.len;
            return false;
        }

        pub fn insert(self: *Self, func: []const u8) error{Full}!void {
            if (self.len >= length)
                return error.Full;

            defer self.len += 1;
            for (self.buf[0..self.len], 0..) |v, i| {
                if (compare(func, v)) {
                    std.mem.copyBackwards(
                        []const u8,
                        self.buf[i + 1 .. self.len + 2],
                        self.buf[i .. self.len + 1],
                    );
                    self.buf[i] = func;
                    return;
                }
            }
            self.buf[self.len] = func;
        }

        pub fn remove(self: *Self, func: []const u8) error{ Empty, ItemNotFound }!void {
            if (self.len == 0) {
                return error.Empty;
            }

            for (self.buf, 0..) |v, i| {
                if (std.mem.eql(u8, v, func)) {
                    std.mem.copyForwards(
                        []const u8,
                        self.buf[i..self.len],
                        self.buf[i + 1 .. self.len + 1],
                    );
                    self.len -= 1;
                    return;
                }
            }
            return error.ItemNotFound;
        }
    };
}

test "SortedStringList(.Right).insert" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, Direction.Right){};
    try foo.insert("sin");
    try foo.insert("cos");
    try foo.insert("rand");
    try foo.insert("tan");
    try foo.insert("normalcdf");
    const expected = [_][]const u8{
        "normalcdf",
        "rand",
        "sin",
        "cos",
        "tan",
    };

    for (foo.buf[0..foo.len], expected) |obs, exp| {
        std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }
}

test "SortedStringList(.Left).insert" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, Direction.Left){};
    try foo.insert("sin");
    try foo.insert("normalcdf");
    try foo.insert("cos");
    try foo.insert("rand");
    try foo.insert("tan");
    const expected = [_][]const u8{
        "sin",
        "cos",
        "tan",
        "rand",
        "normalcdf",
    };

    for (foo.buf[0..foo.len], expected) |obs, exp| {
        std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }
}

test "SortedStringArray(.Right).remove" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, Direction.Right){};
    try foo.insert("sin");
    try foo.insert("cos");
    try foo.insert("rand");
    try foo.insert("tan");
    try foo.insert("normalcdf");

    try foo.remove("tan");
    try foo.remove("normalcdf");
    try foo.remove("sin");
    const expected = [_][]const u8{
        // "normcdf",
        "rand",
        // "sin",
        "cos",
        // "tan",
    };

    for (foo.buf[0..foo.len], expected) |obs, exp| {
        std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }

    try std.testing.expectError(error.ItemNotFound, foo.remove("chicken"));
    try std.testing.expectError(error.ItemNotFound, foo.remove("tan"));
}

test "SortedStringArray(.Left).remove" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, Direction.Left){};
    try foo.insert("sin");
    try foo.insert("cos");
    try foo.insert("rand");
    try foo.insert("tan");
    try foo.insert("normalcdf");

    try foo.remove("cos");
    try foo.remove("normalcdf");
    const expected = [_][]const u8{
        "sin",
        // "cos",
        "tan",
        "rand",
        // "normcdf",
    };

    for (foo.buf[0..foo.len], expected) |obs, exp| {
        std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }

    try std.testing.expectError(error.ItemNotFound, foo.remove("chicken"));
    try std.testing.expectError(error.ItemNotFound, foo.remove("cos"));
}
