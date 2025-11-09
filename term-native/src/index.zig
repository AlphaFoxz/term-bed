const std = @import("std");
const Io = std.Io;
const std_io = @import("./core/std_io.zig");
const ansi = @import("./ansi_util/index.zig");
const tui_app = @import("./core/tui_app.zig");

// ======================== app ========================
pub export fn runApp(logger: *const fn ([*c]const u8) callconv(.c) void) *tui_app.TuiApp {
    return tui_app.runApp(logger);
}

pub export fn exitApp(app: *tui_app.TuiApp) void {
    tui_app.exitApp(app);
}

// ======================== ansi ========================
pub export fn resetStyle() void {
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.format.resetStyleAndFlush(writer) catch unreachable;
}

pub export fn showCursor() void {
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.cursor.showCursorAndFlush(writer) catch unreachable;
}

pub export fn hideCursor() void {
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.cursor.hideCursorAndFlush(writer) catch unreachable;
}

pub export fn clearScreen() void {
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.clear.clearScreenAndFlush(writer) catch unreachable;
}

pub export fn drawText(row: i32, col: i32, cstr: [*:0]const u8) void {
    const s = std.mem.span(cstr);
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.printAndFlush(writer, "\x1b[{d};{d}H{s}", .{ row + 1, col + 1, s }) catch unreachable;
}
