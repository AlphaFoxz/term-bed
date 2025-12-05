const std = @import("std");
const glo_alloc = @import("./core/glo_alloc.zig");
const string = @import("./core/string.zig");
const testing = std.testing;

test "cn char width" {
    try testing.expectEqual(string.getDisplayWidthStd("你"), 2);
    try testing.expectEqual(string.getDisplayWidthStd("好"), 2);
}

test "en char width" {
    try testing.expectEqual(string.getDisplayWidthStd("a"), 1);
    try testing.expectEqual(string.getDisplayWidthStd("😀"), 1);
}

test "cn char len" {
    var c: []const u8 = "你";
    try testing.expectEqual(std.unicode.utf8ByteSequenceLength(c[0]), 3);
    c = "1";
    try testing.expectEqual(std.unicode.utf8ByteSequenceLength(c[0]), 1);
}

test "string iter" {
    glo_alloc.debugMode();
    const str = string.String.initFromSclice("Hello world 你好");
    defer str.deinit();
    const verify = [_][]const u8{
        "H",
        "e",
        "l",
        "l",
        "o",
        " ",
        "w",
        "o",
        "r",
        "l",
        "d",
        " ",
        "你",
        "好",
    };
    var iter = str.iter();

    for (0..verify.len) |i| {
        const next = iter.next().?;
        const v = verify[i];
        try std.testing.expect(std.mem.eql(u8, next, v));
    }
}
