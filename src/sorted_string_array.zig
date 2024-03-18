const std = @import("std");

/// Sorted Array of []u8
pub fn SortedStringArray(comptime length: usize, comptime sort: enum {
    ShortestToLongest,
    LongestToShortest,
}) type {
    return struct {
        const Self = @This();

        buf: [length][]const u8 = undefined,
        len: usize = 0,

        fn compare(left: []const u8, right: []const u8) bool {
            if (sort == .ShortestToLongest)
                return left.len < right.len;
            if (sort == .LongestToShortest)
                return left.len > right.len;
            unreachable;
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

        /// Return a slice owned by SortedStringList
        /// containing all of the strings
        pub fn asSlice(self: Self) []const []const u8 {
            return self.buf[0..self.len];
        }
    };
}

test "SortedStringList(.LongestToShortest).insert" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, .LongestToShortest){};
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

    for (foo.asSlice(), expected) |obs, exp| {
        // std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        // std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }
}

test "SortedStringList(.ShortestToLongest).insert" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, .ShortestToLongest){};
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

    for (foo.asSlice(), expected) |obs, exp| {
        // std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        // std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }
}

test "SortedStringArray(.LongestToShortest).remove" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, .LongestToShortest){};
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

    for (foo.asSlice(), expected) |obs, exp| {
        // std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        // std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }

    try std.testing.expectError(error.ItemNotFound, foo.remove("chicken"));
    try std.testing.expectError(error.ItemNotFound, foo.remove("tan"));
}

test "SortedStringArray(.ShortestToLongest).remove" {
    std.debug.print("\n", .{});
    var foo = SortedStringArray(16, .ShortestToLongest){};
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

    for (foo.asSlice(), expected) |obs, exp| {
        // std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        // std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }

    try std.testing.expectError(error.ItemNotFound, foo.remove("chicken"));
    try std.testing.expectError(error.ItemNotFound, foo.remove("cos"));
}
