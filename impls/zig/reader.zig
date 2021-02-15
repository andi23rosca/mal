const std = @import("std");
const ArrayList = @import("std").ArrayList;

const TkState = enum {
    parseError,
    endOfData,
    findStartOfToken,
    captureSpecialDoubleToken,
    captureString,
    captureSemicolonToken,
    captureNonSpecial,
};

pub const Reader = struct {
    index: u64,
    tokens: ArrayList([]u8),

    pub fn init(allocator: *std.mem.Allocator) Reader {
        return Reader{
            .index = 0,
            .tokens = ArrayList([]u8).init(allocator),
        };
    }
    pub fn deinit(reader: *Reader) void {
        reader.tokens.deinit();
    }
    pub fn next(reader: *Reader) []u8 {
        reader.index += 1;
        return reader.tokens[reader.index - 1];
    }
    pub fn peek(reader: *Reader) []u8 {
        return reader.tokens[reader.index];
    }

    pub fn tokenize(reader: *Reader, input: []u8) !void {
        var index: u64 = 0;
        var tokenStart: u64 = 0;
        var state: TkState = TkState.findStartOfToken;

        while (state != TkState.parseError and state != TkState.endOfData) {
            // Handle end of input
            if (index >= input.len) {
                switch (state) {
                    .captureString, .captureSpecialDoubleToken, .parseError => {
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
                    if (current == '"' and !(input[index - 1] == '\\')) {
                        try reader.tokens.append(input[tokenStart .. index + 1]);
                        index += 1;
                        state = TkState.findStartOfToken;
                        continue;
                    }
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
};

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
