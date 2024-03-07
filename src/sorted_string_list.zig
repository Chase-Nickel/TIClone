const std = @import("std");

const ListError = error{ Full, Empty, FunctionNotFound };

/// Sorted ArrayList of []u8
/// Greatest length to shortest
pub fn SortedStringList(comptime length: usize) type {
    return struct {
        const Self = @This();

        buf: [length][]u8 = undefined,
        len: usize = 0,

        pub fn insert(self: *Self, func: []u8) !void {
            if (self.len >= length)
                return ListError.Full;

            defer self.len += 1;
            for (self.buf[0..self.len], 0..) |v, i| {
                if (func.len > v.len) {
                    std.mem.copyBackwards(
                        []u8,
                        self.buf[i + 1 .. self.len + 2],
                        self.buf[i .. self.len + 1],
                    );
                    self.buf[i] = func;
                    return;
                }
            }
            self.buf[self.len] = func;
        }

        pub fn remove(self: *Self, func: []u8) !void {
            if (self.len == 0) {
                return ListError.Empty;
            }

            for (self.buf, 0..) |v, i| {
                if (std.mem.eql(u8, v, func)) {
                    std.mem.copyForwards(
                        []u8,
                        self.buf[i..self.len],
                        self.buf[i + 1 .. self.len + 1],
                    );
                    self.len -= 1;
                    return;
                }
            }
            return ListError.FunctionNotFound;
        }
    };
}

test "SortedStringList.insert" {
    std.debug.print("\n", .{});
    var foo = SortedStringList(16){};
    var sin = [_]u8{ 's', 'i', 'n' };
    var cos = [_]u8{ 'c', 'o', 's' };
    var rand = [_]u8{ 'r', 'a', 'n', 'd' };
    var tan = [_]u8{ 't', 'a', 'n' };
    var normcdf = [_]u8{ 'n', 'o', 'r', 'm', 'c', 'd', 'f' };
    try foo.insert(&sin);
    try foo.insert(&cos);
    try foo.insert(&rand);
    try foo.insert(&tan);
    try foo.insert(&normcdf);
    const expected = [_][]u8{
        &normcdf,
        &rand,
        &sin,
        &cos,
        &tan,
    };

    for (foo.buf[0..foo.len], expected) |obs, exp| {
        std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }
}

test "SortedStringList.remove" {
    std.debug.print("\n", .{});
    var foo = SortedStringList(16){};
    var sin = [_]u8{ 's', 'i', 'n' };
    var cos = [_]u8{ 'c', 'o', 's' };
    var rand = [_]u8{ 'r', 'a', 'n', 'd' };
    var tan = [_]u8{ 't', 'a', 'n' };
    var normcdf = [_]u8{ 'n', 'o', 'r', 'm', 'c', 'd', 'f' };
    try foo.insert(&sin);
    try foo.insert(&cos);
    try foo.insert(&rand);
    try foo.insert(&tan);
    try foo.insert(&normcdf);

    try foo.remove(&tan);
    try foo.remove(&normcdf);
    try foo.remove(&sin);
    const expected = [_][]u8{
        // &normcdf,
        &rand,
        // &sin,
        &cos,
        // &tan,
    };

    for (foo.buf[0..foo.len], expected) |obs, exp| {
        std.debug.print("Expected: {any}  |  Got: {any}", .{ exp, obs });
        std.debug.print("\n", .{});
        try std.testing.expect(std.mem.eql(u8, obs, exp));
    }
}

