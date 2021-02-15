const std = @import("std");
const ArrayList = @import("std").ArrayList;

pub const Reader = struct {
    index: u64 = 0, tokens: ArrayList([]u8)
};

pub fn init(reader: *Reader, allocator: *std.mem.Allocator) Reader {
    reader.tokens = ArrayList([]u8).init(allocator);
}
pub fn deinit(reader: *Reader) Reader {
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

    while (index < input.len) {
        var current = input[index];
        if (isWhitespace(current)) {
            index += 1;
            continue;
        }
        if (current == '~' and index + 1 < input.len and input[index + 1] == '@') {
            reader.tokens.append(input[index .. index + 2]);
            index += 2;
            continue;
        }
        if (isSpecialSingleChar(current)) {
            reader.tokens.append(input[index .. index + 1]);
            index += 1;
            continue;
        }
        if (current == '"') {
            index += 1;
            var end: u64 = index;
            var stop = false;
            while (!stop and end < input.len) {
                const c = input[end];
                if (c == '"') {
                    reader.tokens.append(input[index..end]);
                    stop = true;
                    continue;
                }
                if (c == '\\' and end + 1 < input.len and input[end + 1] == '\"') {
                    end += 2;
                    continue;
                }
                end += 1;
            }
            if (!stop) return error.UnterminatedString;
            index = end + 1;
            continue;
        }
    }
}

pub fn isWhitespace(c: u8) bool {
    return c == ' ';
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
