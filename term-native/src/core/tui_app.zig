const std = @import("std");
const Io = std.Io;
const tui_context = @import("./tui_context.zig");
const ansi = @import("../ansi_util.zig");
const std_io = @import("./std_io.zig");
const alloc = @import("./alloc.zig");
const input = @import("../input.zig");
const logger = @import("./logger.zig");

pub const TuiApp = struct {
    context: tui_context.TuiContext,

    pub fn run(ctx: tui_context.TuiContext) TuiApp {
        var app = TuiApp{ .context = ctx };
        app.forceRender();
        return app;
    }

    pub fn forceRender(self: *TuiApp) void {
        // 1. 设置 UTF-8 编码（Windows）
        const writer: *Io.Writer = &std_io.writer.interface;
        ansi.format.updateStyle(writer, ansi.style.Style{ .background = ansi.style.Color{ .RGB = ansi.style.ColorRGB{
            .r = 127,
            .g = 96,
            .b = 254,
        } } }, null) catch unreachable;
        for (0..self.context.screen_rect.rows) |row| {
            for (0..self.context.screen_rect.cols) |col| {
                ansi.writeAllToPos(writer, col, row, "你") catch unreachable;
            }
        }
        ansi.cursor.setCursor(writer, 0, 0) catch unreachable;
        ansi.terminal.setTitle(writer, "term-bed") catch unreachable;
        writer.flush() catch unreachable;
    }

    pub fn exit(_: *TuiApp) void {}
};

pub fn runApp(js_cb: *const fn ([*c]const u8) callconv(.c) void) *TuiApp {
    alloc.init();
    logger.init(js_cb);
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.terminal.enterAlternateScreen(writer) catch unreachable;
    ansi.cursor.hideCursorAndFlush(writer) catch unreachable;
    const tuiContext = tui_context.createTuiContext();
    const app_ptr = alloc.allocator().create((TuiApp)) catch {
        logger.logError("Out of memory");
        std.process.exit(1);
    };
    app_ptr.* = TuiApp.run(tuiContext);
    logger.logInfo("TuiApp created");
    input.startListening();
    return app_ptr;
}

pub fn exitApp(app_ptr: *TuiApp) void {
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.cursor.showCursor(writer) catch unreachable;
    ansi.terminal.leaveAlternateScreen(writer) catch unreachable;
    input.stopListening();
    app_ptr.exit();
    ansi.clear.clearScreenAndFlush(writer) catch unreachable;
    std_io.flushAll();
    alloc.allocator().destroy(app_ptr);
    alloc.deinit();
}
