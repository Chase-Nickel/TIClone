const std = @import("std");

const ArrayError = error{OutOfBounds};

const TIFunction = []u8; // Function is just its name

pub fn TIFunctionList(comptime length: usize) type {
    return struct {
        const Self = @This();

        buf: [length]TIFunction = undefined,
        len: usize = 0,

        pub fn insert(self: *Self, func: TIFunction) !void {
            if (self.len >= length)
                return ArrayError.OutOfBounds;

            defer self.len += 1;
            for (self.buf[0..self.len], 0..) |v, i| {
                if (func.len > v.len) {
                    std.mem.copyBackwards(
                        TIFunction,
                        self.buf[i..self.len+1],
                        self.buf[0..i],
                    );
                    self.buf[i] = v;
                    return;
                }
            }
            self.buf[self.len] = func;
        }

        pub fn remove(self: *Self, func: TIFunction) !void {
            _ = func;
            _ = self;
            @compileError("TIFunctionList.remove not implemented");
        }
    };
}

test "Is this thing even working??" {
    var foo = TIFunctionList(16){};
    var sin = [_]u8{ 's', 'i', 'n' };
    var cos = [_]u8{ 'c', 'o', 's' };
    var rand = [_]u8{ 'r', 'a', 'n', 'd' };
    var tan = [_]u8{ 't', 'a', 'n' };
    try foo.insert(&sin);
    try foo.insert(&cos);
    try foo.insert(&rand);
    try foo.insert(&tan);
    const expected = [_]TIFunction{
        &rand,
        &sin,
        &cos,
        &tan,
    };

    for (foo.buf[0..foo.len], expected) |obs, exp| {
        std.debug.print("\nExpected: {any}  |  Got: {any}", .{exp, obs});
        // try std.testing.expect(std.mem.eql(u8, obs, exp));
    }
    std.debug.print("\n", .{});
}
