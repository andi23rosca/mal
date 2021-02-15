const ArrayList = @import("std").ArrayList;

pub const Reader = struct {
    index: u64 = 0, tokens: ArrayList([]u8)
};

pub fn next(reader: *Reader) []u8 {
    reader.index += 1;
    return reader.tokens[reader.index - 1];
}
pub fn peek(reader: *Reader) []u8 {
    return reader.tokens[reader.index];
}
