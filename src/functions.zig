const std = @import("std");

const TIFunctionListError = error{ Full, Empty, FunctionNotFound };

const TIFunction = []u8; // Function is just its name

pub fn TIFunctionList(comptime length: usize) type {
    return struct {
        const Self = @This();

        buf: [length]TIFunction = undefined,
        len: usize = 0,

        pub fn insert(self: *Self, func: TIFunction) !void {
            if (self.len >= length)
                return TIFunctionListError.Full;

            defer self.len += 1;
            for (self.buf[0..self.len], 0..) |v, i| {
                if (func.len > v.len) {
                    std.mem.copyBackwards(
                        TIFunction,
                        self.buf[i + 1 .. self.len + 2],
                        self.buf[i .. self.len + 1],
                    );
                    self.buf[i] = func;
                    return;
                }
            }
            self.buf[self.len] = func;
        }

        pub fn remove(self: *Self, func: TIFunction) !void {
            if (self.len == 0) {
                return TIFunctionListError.Empty;
            }

            for (self.buf, 0..) |v, i| {
                if (std.mem.eql(u8, v, func)) {
                    std.mem.copyForwards(
                        TIFunction,
                        self.buf[i..self.len],
                        self.buf[i + 1 .. self.len + 1],
                    );
                    self.len -= 1;
                    return;
                }
            }
            return TIFunctionListError.FunctionNotFound;
        }
    };
}

test "Insert test" {
    std.debug.print("\n", .{});
    var foo = TIFunctionList(16){};
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
    const expected = [_]TIFunction{
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

test "Remove test" {
    std.debug.print("\n", .{});
    var foo = TIFunctionList(16){};
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
    const expected = [_]TIFunction{
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

