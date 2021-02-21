const std = @import("std");
const types = @import("types.zig");

pub const MalEnv = struct {
    outer: ?*MalEnv,
    data: std.StringHashMap(types.MalExpr),
    allocator: *std.mem.Allocator,

    pub fn init(allocator: *std.mem.Allocator, outer: ?*MalEnv) MalEnv {
        return MalEnv{
            .allocator = allocator,
            .outer = outer,
            .data = std.StringHashMap(types.MalExpr).init(allocator),
        };
    }
    pub fn deinit(env: *MalEnv) void {
        env.data.deinit();
    }
    pub fn set(env: *MalEnv, key: []const u8, value: types.MalExpr) !void {
        try env.data.put(key, value);
    }
    pub fn find(env: *MalEnv, key: []const u8) ?*MalEnv {
        if (env.data.contains(key)) {
            var res = env;
            return res;
        } else {
            if (env.outer) |outer| {
                return outer.find(key);
            }
        }
        return null;
    }
    pub fn get(env: *MalEnv, key: []const u8) ?types.MalExpr {
        if (env.find(key)) |containingEnv| {
            // std.debug.warn("found env\n", .{});
            return containingEnv.data.get(key);
        }
        std.debug.print("{s} not defined", .{key});
        return null;
    }
};
