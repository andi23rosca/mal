const std = @import("std");
const eql = std.mem.eql;
const types = @import("types.zig");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const MalExpr = types.MalExpr;
const MalKind = types.MalKind;
const TkState = types.TkState;

pub const Reader = struct {
    index: u64,
    tokens: ArrayList([]u8),
    allocator: *std.mem.Allocator,

    pub fn init(allocator: *std.mem.Allocator) Reader {
        return Reader{
            .index = 0,
            .tokens = ArrayList([]u8).init(allocator),
            .allocator = allocator,
        };
    }
    pub fn deinit(reader: *Reader) void {
        reader.tokens.deinit();
    }
    pub fn next(reader: *Reader) void {
        reader.index += 1;
    }
    pub fn peek(reader: *Reader) []u8 {
        return reader.tokens.items[reader.index];
    }

    pub fn tokenize(reader: *Reader, input: []u8) !void {
        var index: u64 = 0;
        var tokenStart: u64 = 0;
        var state: TkState = TkState.findStartOfToken;

        while (state != TkState.parseError and state != TkState.endOfData) {
            // Handle end of input
            if (index >= input.len) {
                switch (state) {
                    .captureString, .captureStringEscape => {
                        std.debug.warn("{s}\n", .{"expected \", got EOF"});
                        state = TkState.parseError;
                    },
                    .captureSpecialDoubleToken, .parseError => {
                        state = TkState.parseError;
                    },
                    .captureNonSpecial, .captureSemicolonToken => {
                        try reader.tokens.append(input[tokenStart..index]);
                        state = TkState.endOfData;
                    },
                    .endOfData, .findStartOfToken => {
                        state = TkState.endOfData;
                    },
                }
                continue;
            }

            const current = input[index];

            switch (state) {
                .findStartOfToken => {
                    if (isDelimiter(current)) {
                        index += 1;
                        continue;
                    }
                    if (current == '~') {
                        state = TkState.captureSpecialDoubleToken;
                        tokenStart = index;
                        index += 1;
                        continue;
                    }
                    if (isSpecialSingleChar(current)) {
                        try reader.tokens.append(input[index .. index + 1]);
                        index += 1;
                        continue;
                    }
                    if (current == '"') {
                        state = TkState.captureString;
                        tokenStart = index;
                        index += 1;
                        continue;
                    }
                    if (current == ';') {
                        state = TkState.captureSemicolonToken;
                        tokenStart = index;
                        index += 1;
                        continue;
                    }
                    state = TkState.captureNonSpecial;
                    tokenStart = index;
                    index += 1;
                },
                .captureSpecialDoubleToken => {
                    if (current == '@') {
                        try reader.tokens.append(input[tokenStart .. index + 1]);
                        index += 1;
                        state = TkState.findStartOfToken;
                        continue;
                    }
                    try reader.tokens.append(input[index - 1 .. index]);
                    state = TkState.findStartOfToken;
                },
                .captureString => {
                    if (current == '"') {
                        try reader.tokens.append(input[tokenStart .. index + 1]);
                        index += 1;
                        state = TkState.findStartOfToken;
                        continue;
                    }
                    if (current == '\\') {
                        state = TkState.captureStringEscape;
                        index += 1;
                        continue;
                    }
                    index += 1;
                },
                .captureStringEscape => {
                    state = TkState.captureString;
                    index += 1;
                },
                .captureSemicolonToken => {
                    if (isDelimiter(current) or isSpecialSingleChar(current) or current == '~' or current == ';' or current == '"') {
                        try reader.tokens.append(input[tokenStart..index]);
                        state = TkState.findStartOfToken;
                        continue;
                    }
                    index += 1;
                },
                .captureNonSpecial => {
                    if (isDelimiter(current) or isSpecialSingleChar(current) or current == '~' or current == ';' or current == '"') {
                        try reader.tokens.append(input[tokenStart..index]);
                        state = TkState.findStartOfToken;
                        continue;
                    }
                    index += 1;
                },
                .parseError => {
                    index += 1;
                    continue;
                },
                .endOfData => {
                    index += 1;
                    continue;
                },
            }
        }
        if (state == TkState.parseError) return error.ParseError;
    }

    pub fn readForm(reader: *Reader) anyerror!MalExpr {
        const current = reader.peek();
        if (strEql(current, "("))
            return try reader.readList();
        if (strEql(current, "["))
            return try reader.readVector();
        // if (strEql(current, "{"))
        //     return try reader.readHash();
        return try reader.readAtom();
    }
    // pub fn readHash(reader: *Reader) !StringHashMap(MalExpr) {
    //     var malHash = MalExpr{ .hash = StringHashMap(MalExpr).init(reader.allocator) };
    //     reader.next();
    //     var hashDone = false;
    //     while (!hashDone and reader.index < reader.tokens.items.len) {
    //         var key = reader.peek();
    //         if (strEql(key, "}")) {
    //             hashDone = true;
    //             reader.next();
    //             continue;
    //         }
    //         reader.next();
    //         if (reader.index >= reader.tokens.items.len) {
    //             continue;
    //         }
    //         var value = try reader.readForm();
    //         try malHash.hash.put(key, value);
    //     }
    //     if (!hashDone) {
    //         std.debug.warn("expected }, got EOF\n", .{});
    //         return error.UnmatchedParens;
    //     }
    //     return malHash;
    // }
    pub fn readSequence(reader: *Reader, seqEndSym: []const u8) !ArrayList(MalExpr) {
        var ls = ArrayList(MalExpr).init(reader.allocator);
        reader.next();
        var listDone = false;

        while (!listDone and reader.index < reader.tokens.items.len) {
            var token = reader.peek();
            if (strEql(token, seqEndSym)) {
                listDone = true;
                reader.next();
                continue;
            }
            var form = try reader.readForm();
            try ls.append(form);
        }
        if (!listDone) {
            std.debug.warn("expected {s}, got EOF\n", .{seqEndSym});
            return error.UnmatchedParens;
        }
        return ls;
    }
    pub fn readList(reader: *Reader) !MalExpr {
        var ls = try reader.readSequence(")");
        return MalExpr{ .list = ls };
    }
    pub fn readVector(reader: *Reader) !MalExpr {
        var vec = try reader.readSequence("]");
        return MalExpr{ .vector = vec };
    }
    pub fn readAtom(reader: *Reader) !MalExpr {
        var token = reader.peek();
        reader.next();

        if (std.fmt.parseFloat(f64, token)) |num| {
            if (!strEql(token, "+") and !strEql(token, "-"))
                return MalExpr{ .number = num };
        } else |_| {}

        if (token[0] == '"') {
            var str = ArrayList(u8).init(reader.allocator);
            try str.appendSlice(token[1 .. token.len - 1]);
            return MalExpr{ .string = str };
        }
        if (token[0] == ':') {
            var str = ArrayList(u8).init(reader.allocator);
            try str.appendSlice(token);
            return MalExpr{ .keyword = str };
        }
        if (strEql(token, "true") or strEql(token, "false")) {
            return MalExpr{ .boolean = strEql(token, "true") };
        }
        if (strEql(token, "nil")) {
            return MalExpr.nil;
        }

        var str = ArrayList(u8).init(reader.allocator);
        try str.appendSlice(token);
        return MalExpr{ .symbol = str };
    }
};
pub fn readStr(allocator: *std.mem.Allocator, input: []u8) !MalExpr {
    var reader = Reader.init(allocator);
    defer reader.deinit();
    try reader.tokenize(input);
    return reader.readForm();
}

// test "tokenizer" {
//     var allocator = std.testing.allocator;
//     var reader = Reader.init(allocator);
//     defer reader.deinit();

//     var str = try allocator.dupe(u8,
//         \\\(sadf "asd" a;s,d ~@sd
//     );
//     defer allocator.free(str);

//     try reader.tokenize(str);
//     for (reader.tokens.items) |token| {
//         std.debug.print("{s}\n", .{token});
//     }
// }

pub fn strEql(s1: []u8, s2: []const u8) bool {
    return eql(u8, s1, s2);
}
test "strEql" {
    var s1 = try std.testing.allocator.dupe(u8, "abc");
    defer std.testing.allocator.free(s1);
    var s2 = try std.testing.allocator.dupe(u8, "abc");
    defer std.testing.allocator.free(s2);
    std.testing.expect(strEql(s1, s2));
}
pub fn isDelimiter(c: u8) bool {
    return c == ' ' or c == '\n' or c == '\r' or c == '\t' or c == ',';
}
pub fn isSpecialSingleChar(c: u8) bool {
    return c == '[' or
        c == ']' or
        c == '{' or
        c == '}' or
        c == '(' or
        c == ')' or
        c == '\'' or
        c == '`' or
        c == '~' or
        c == '^' or
        c == '@';
}
