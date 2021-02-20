const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHasMap = std.AutoHashMap;

pub const TkState = enum {
    parseError,
    endOfData,
    findStartOfToken,
    captureSpecialDoubleToken,
    captureString,
    captureStringEscape,
    captureSemicolonToken,
    captureNonSpecial,
};

pub const MalKind = enum {
    list,
    number,
    symbol,
    boolean,
    string,
    nil,
    // hash,
    vector,
    keyword,
    func,
};

pub const MalExpr = union(MalKind) {
    number: f64,
    boolean: bool,
    nil: void,
    string: ArrayList(u8),
    symbol: ArrayList(u8),
    keyword: ArrayList(u8),
    list: ArrayList(MalExpr),
    vector: ArrayList(MalExpr),
    // hash: AutoHashMap(u8, MalExpr),
    func: fn (args: []MalExpr, out: *MalExpr) void,
};
