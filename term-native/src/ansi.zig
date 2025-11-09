const std = @import("std");
const ansi = @import("./ansi_util/index.zig");
const std_io = @import("./core/std_io.zig");

pub export fn resetStyle() void {
    const writer = std_io.getStdWriter();
    ansi.format.resetStyle(writer) catch unreachable;
}

pub export fn showCursor() void {
    const writer = std_io.getStdWriter();
    ansi.cursor.showCursor(writer) catch unreachable;
}

pub export fn hideCursor() void {
    const writer = std_io.getStdWriter();
    ansi.cursor.hideCursor(writer) catch unreachable;
}

pub export fn clearScreen() void {
    const writer = std_io.getStdWriter();
    ansi.clear.clearScreen(writer) catch unreachable;
}

pub export fn drawText(row: i32, col: i32, cstr: [*:0]const u8) void {
    const s = std.mem.span(cstr);
    const writer = std_io.getStdWriter();
    writer.print("\x1b[{d};{d}H{s}", .{ row + 1, col + 1, s }) catch unreachable;
}
