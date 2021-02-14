const std = @import("std");
const print = std.debug.print;
const io = std.io;

const Allocator = std.heap.c_allocator;

fn READ(pr: []u8) []u8 {
    return pr;
}
fn EVAL(pr: []u8) []u8 {
    return pr;
}
fn PRINT(pr: []u8) []u8 {
    return pr;
}

fn rep(pr: []u8) []u8 {
    return PRINT(EVAL(READ(pr)));
}

pub fn main() anyerror!void {
    const max_size = 1024;
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn().reader();

    var buf: [max_size]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var alloc = &fba.allocator;

    // const bytes = try alloc.allocator.alloc(u8, max_size);
    while (true) {
        try stdout.print("user> ", .{});
        const pr = try stdin.readUntilDelimiterAlloc(alloc, '\n', max_size);
        const toOut = rep(pr);
        print("\n{s}\n", .{toOut});
        alloc.free(pr);
    }
}
