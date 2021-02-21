const std = @import("std");
const print = std.debug.print;
const io = std.io;
const readStr = @import("reader.zig").readStr;
const strEql = @import("reader.zig").strEql;
const MalExpr = @import("types.zig").MalExpr;
const printStr = @import("printer.zig").printStr;
const MalEnv = @import("env.zig").MalEnv;

fn READ(allocator: *std.mem.Allocator, pr: []u8) !MalExpr {
    return try readStr(allocator, pr);
}

fn evalAst(allocator: *std.mem.Allocator, ast: MalExpr, env: *MalEnv) !MalExpr {
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
fn EVAL(allocator: *std.mem.Allocator, ast: MalExpr, env: *MalEnv) anyerror!MalExpr {
    // return ast;
    switch (ast) {
        .list => |list| {
            if (list.items.len == 0) {
                return ast;
            }
            if (strEql(list.items[0].symbol.items, "def!")) {
                var key = list.items[1].symbol.items;
                var val = try EVAL(allocator, list.items[2], env);
                try env.set(key, val);
                return val;
            }
            if (strEql(list.items[0].symbol.items, "let*")) {
                var outer = env;
                var scope = MalEnv.init(allocator, outer);
                defer scope.deinit();
                var bindings = list.items[1].list.items;
                if (@mod(bindings.len, 2) != 0) {
                    std.debug.print("Let bindings should have an even number of items", .{});
                    return error.UnevenNumberOfBindings;
                }
                var i: u32 = 0;
                while (i < bindings.len) : (i += 2) {
                    var key = bindings[i].symbol.items;
                    var val = try EVAL(allocator, bindings[i + 1], &scope);
                    try scope.set(key, val);
                }
                return try EVAL(allocator, list.items[2], &scope);
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

fn malAdd(args: []MalExpr, out: *MalExpr) void {
    out.number = args[0].number;
    for (args[1..]) |arg| {
        out.number += arg.number;
    }
}
fn malSub(args: []MalExpr, out: *MalExpr) void {
    if (args.len == 1) {
        out.number = -args[0].number;
        return;
    }
    out.number = args[0].number;
    for (args[1..]) |arg| {
        out.number -= arg.number;
    }
}
fn malMult(args: []MalExpr, out: *MalExpr) void {
    out.number = args[0].number;
    for (args[1..]) |arg| {
        out.number *= arg.number;
    }
}
fn malDiv(args: []MalExpr, out: *MalExpr) void {
    out.number = args[0].number;
    for (args[1..]) |arg| {
        out.number /= arg.number;
    }
}
fn rep(allocator: *std.mem.Allocator, pr: []u8, env: *MalEnv) ![]u8 {
    var read = try READ(allocator, pr);
    var evaled = try EVAL(allocator, read, env);
    var printed = try PRINT(allocator, evaled);
    return printed;
}

pub fn main() anyerror!void {
    const max_size = 1024;
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn().reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var alloc = &arena.allocator;

    var env = MalEnv.init(alloc, null);
    try env.set("+", MalExpr{ .func = malAdd });
    try env.set("-", MalExpr{ .func = malSub });
    try env.set("*", MalExpr{ .func = malMult });
    try env.set("/", MalExpr{ .func = malDiv });

    while (true) {
        try stdout.print("user> ", .{});
        const input = try stdin.readUntilDelimiterAlloc(alloc, '\n', max_size);

        const output = rep(alloc, input, &env) catch "";
        try stdout.print("{s}", .{output});
        try stdout.print("\n", .{});
    }
    arena.deinit();
}

test "hash map" {
    var alloc = std.testing.allocator;
    var hash = std.StringHashMap(fn () void).init(alloc);
    defer hash.deinit();
}
