const std = @import("std");
const print = std.debug.print;
const io = std.io;
const readStr = @import("reader.zig").readStr;
const MalExpr = @import("types.zig").MalExpr;
const printStr = @import("printer.zig").printStr;

const MalEnv = std.StringHashMap(MalExpr);

fn READ(allocator: *std.mem.Allocator, pr: []u8) !MalExpr {
    return try readStr(allocator, pr);
}

fn evalAst(allocator: *std.mem.Allocator, ast: MalExpr, env: MalEnv) !MalExpr {
    switch (ast) {
        .symbol => |value| {
            if (env.get(value.items)) |val| {
                return val;
            } else {
                std.debug.warn("'{s}' not found.", .{value.items});
                return error.SymbolNotFound;
            }
        },
        .list => |values| {
            var evaledList = MalExpr{ .list = std.ArrayList(MalExpr).init(allocator) };
            for (values.items) |value| {
                var evaled = try EVAL(allocator, value, env);
                try evaledList.list.append(evaled);
            }
            return evaledList;
        },
        .vector => |values| {
            var evaledList = MalExpr{ .vector = std.ArrayList(MalExpr).init(allocator) };
            for (values.items) |value| {
                var evaled = try EVAL(allocator, value, env);
                try evaledList.list.append(evaled);
            }
            return evaledList;
        },
        else => {
            return ast;
        },
    }
}

fn malAdd(args: []MalExpr, out: *MalExpr) void {
    out.number = args[0].number + args[1].number;
}
fn malSub(args: []MalExpr, out: *MalExpr) void {
    out.number = args[0].number - args[1].number;
}
fn malMult(args: []MalExpr, out: *MalExpr) void {
    out.number = args[0].number * args[1].number;
}
fn malDiv(args: []MalExpr, out: *MalExpr) void {
    out.number = args[0].number / args[1].number;
}
fn EVAL(allocator: *std.mem.Allocator, ast: MalExpr, env: MalEnv) anyerror!MalExpr {
    // return ast;
    switch (ast) {
        .list => |list| {
            if (list.items.len == 0) {
                return ast;
            }
            var evaled = try evalAst(allocator, ast, env);
            var out = MalExpr{ .number = undefined };
            var func = evaled.list.items[0];
            func.func(evaled.list.items[1..], &out);
            return out;
        },
        else => {
            return try evalAst(allocator, ast, env);
        },
    }
}
fn PRINT(allocator: *std.mem.Allocator, pr: MalExpr) ![]u8 {
    return try printStr(allocator, pr);
}

fn rep(allocator: *std.mem.Allocator, pr: []u8) ![]u8 {
    var env = MalEnv.init(allocator);
    try env.put("+", MalExpr{ .func = malAdd });
    try env.put("-", MalExpr{ .func = malSub });
    try env.put("*", MalExpr{ .func = malMult });
    try env.put("/", MalExpr{ .func = malDiv });

    var read = try READ(allocator, pr);
    var evaled = try EVAL(allocator, read, env);
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

        const output = rep(alloc, input) catch "";
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
