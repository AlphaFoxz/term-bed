const builtin = @import("builtin");
const std = @import("std");
const Io = std.Io;
const std_io = @import("./core/std_io.zig");
const ansi = @import("./ansi_util.zig");
const string = @import("./core/string.zig");
const logger = @import("./core/logger.zig");

const TuiApp = @import("./core/tui_app.zig").TuiApp;

pub fn forceRenderApp(app_ptr: *TuiApp) void {
    // 1. 设置 UTF-8 编码（Windows）
    const writer: *Io.Writer = &std_io.writer.interface;
    const is_windows = @import("builtin").os.tag == .windows;
    if (is_windows) {
        setWindowsUTF8() catch {};
    }
    ansi.format.updateStyle(writer, ansi.style.Style{ .background = ansi.style.Color{ .RGB = ansi.style.ColorRGB{
        .r = 127,
        .g = 96,
        .b = 254,
    } } }, null) catch unreachable;

    const str = string.String.initFromSclice("Hello world 你好");
    defer str.deinit();
    var iter = str.iter();

    var compute_col: u16 = 0;
    for (0..app_ptr.context.screen_rect.rows) |row| {
        compute_col = 0;
        var should_skip: u16 = 0;
        for (0..app_ptr.context.screen_rect.cols) |col| {
            if (should_skip > 0) {
                should_skip -= 1;
                continue;
            }
            const peeked = iter.preview();
            if (peeked == null) {
                ansi.writeAllToPos(writer, col, row, " ") catch unreachable;
                continue;
            }
            const char_len: u16 = @intCast(string.getDisplayWidthStd(peeked.?));
            should_skip = char_len - 1;
            compute_col += char_len;
            logger.logDebugFmt("字符: {s}, 长度: {}", .{ peeked.?, char_len });
            ansi.writeAllToPos(writer, col, row, peeked.?) catch unreachable;
            _ = iter.next();
        }
    }
    ansi.cursor.setCursor(writer, 0, 0) catch unreachable;
    ansi.terminal.setTitle(writer, "term-bed") catch unreachable;
    writer.flush() catch unreachable;
}

var next_char: []const u8 = "1";
fn nextChar() []const u8 {
    next_char = if (std.mem.eql(u8, next_char, "1")) "你" else "1";
    return next_char;
}
fn previewNextChar() []const u8 {
    return if (std.mem.eql(u8, next_char, "1")) "你" else "1";
}

fn setWindowsUTF8() !void {
    if (@import("builtin").os.tag != .windows) return;

    const windows = std.os.windows;
    const kernel32 = windows.kernel32;

    // 设置控制台输出代码页为 UTF-8 (65001)
    _ = kernel32.SetConsoleOutputCP(65001);
    // _ = kernel32.SetConsoleCP(65001);
}

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

    for (0..verify.len) |_| {
        try std.testing.expect(std.mem.eql(u8, iter.next().?, verify[iter.index]));
    }
}
