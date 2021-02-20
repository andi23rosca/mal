const std = @import("std");
const print = std.debug.print;
const io = std.io;
const readStr = @import("reader.zig").readStr;
const MalExpr = @import("types.zig").MalExpr;
const printStr = @import("printer.zig").printStr;

fn READ(allocator: *std.mem.Allocator, pr: []u8) !MalExpr {
    return try readStr(allocator, pr);
}

fn EVAL(pr: MalExpr) MalExpr {
    return pr;
}
fn PRINT(allocator: *std.mem.Allocator, pr: MalExpr) ![]u8 {
    return try printStr(allocator, pr);
}

fn rep(allocator: *std.mem.Allocator, pr: []u8) ![]u8 {
    var read = try READ(allocator, pr);
    var evaled = EVAL(read);
    var printed = try PRINT(allocator, evaled);
    return printed;
}

pub fn main() anyerror!void {
    const max_size = 1024;
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn().reader();

    while (true) {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        var alloc = &arena.allocator;

        try stdout.print("user> ", .{});
        const input = try stdin.readUntilDelimiterAlloc(alloc, '\n', max_size);

        const output = try rep(alloc, input);
        try stdout.print("{s}", .{output});
        try stdout.print("\n", .{});

        arena.deinit();
    }
}

test "hash map" {
    var alloc = std.testing.allocator;
    var hash = std.StringHashMap(fn () void).init(alloc);
    defer hash.deinit();
}
