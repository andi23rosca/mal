const std = @import("std");
const MalExpr = @import("types.zig").MalExpr;

pub fn printStr(allocator: *std.mem.Allocator, ast: MalExpr) anyerror![]u8 {
    switch (ast) {
        .number => |value| {
            var buf: [1079]u8 = undefined;
            var result = try std.fmt.bufPrint(&buf, "{d}", .{value});
            return result[0..];
        },
        .symbol, .keyword => |value| {
            return value.items;
        },
        .string => |value| {
            var result: []u8 = try allocator.alloc(u8, value.items.len + 2);
            std.mem.copy(u8, result[0..1], "\"");
            std.mem.copy(u8, result[1 .. result.len - 1], value.items);
            std.mem.copy(u8, result[result.len - 1 ..], "\"");
            return result;
        },
        .nil => {
            var result = try allocator.dupe(u8, "nil");
            return result;
        },
        .boolean => |value| {
            if (value) {
                return try allocator.dupe(u8, "true");
            }
            return try allocator.dupe(u8, "false");
        },
        .list, .vector => |value| {
            var result = std.ArrayList(u8).init(allocator);
            try result.appendSlice("(");
            for (value.items) |token, index| {
                var printed = try printStr(allocator, token);
                try result.appendSlice(printed);
                if (index < value.items.len - 1)
                    try result.appendSlice(" ");
            }
            try result.appendSlice(")");
            return result.items;
        },
    }
}

test "arraylist" {
    var alloc = std.testing.allocator;
    var num: f64 = 23.1;
    var ast = MalExpr{ .number = num };
    var out = try printStr(alloc, ast);
    std.testing.expect(std.mem.eql(u8, out, "23.1"));

    var list = std.ArrayList(MalExpr).init(alloc);
    ast = MalExpr{ .list = list };
    try ast.list.append(MalExpr{ .number = 23 });
    try ast.list.append(MalExpr{ .boolean = true });
    out = try printStr(alloc, ast);
    std.debug.warn("{s}", .{out});
    std.testing.expect(std.mem.eql(u8, out, "(23 true)"));

    // alloc.free(out);/s
    list.deinit();
}
