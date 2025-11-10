const std = @import("std");
const Io = std.Io;
const std_io = @import("./core/std_io.zig");
const ansi = @import("./ansi_util.zig");

const TuiApp = @import("./core/tui_app.zig").TuiApp;

pub fn forceRenderApp(app_ptr: *TuiApp) void {
    // 1. 设置 UTF-8 编码（Windows）
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.format.updateStyle(writer, ansi.style.Style{ .background = ansi.style.Color{ .RGB = ansi.style.ColorRGB{
        .r = 127,
        .g = 96,
        .b = 254,
    } } }, null) catch unreachable;
    for (0..app_ptr.context.screen_rect.rows) |row| {
        for (0..app_ptr.context.screen_rect.cols) |col| {
            ansi.writeAllToPos(writer, col, row, "你") catch unreachable;
        }
    }
    ansi.cursor.setCursor(writer, 0, 0) catch unreachable;
    ansi.terminal.setTitle(writer, "term-bed") catch unreachable;
    writer.flush() catch unreachable;
}
