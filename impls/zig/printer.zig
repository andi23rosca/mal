const std = @import("std");
const MalExpr = @import("reader.zig").MalExpr;

pub fn printStr(allocator: *std.mem.Allocator, ast: MalExpr) ![]u8 {
    var result: []u8;
    switch (ast) {
        .number => |value| {},
    }
}
