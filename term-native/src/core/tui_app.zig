const std = @import("std");
const Io = std.Io;
const tui_context = @import("./tui_context.zig");
const ansi = @import("../ansi_util.zig");
const std_io = @import("./std_io.zig");
const alloc = @import("./alloc.zig");
const input = @import("../input.zig");
// const logger = @import("./logger.zig");
const logger = @import("./logger.zig");

pub const TuiApp = struct {
    context: tui_context.TuiContext,

    pub fn run(ctx: tui_context.TuiContext) TuiApp {
        return TuiApp{ .context = ctx };
    }
    pub fn exit(_: *TuiApp) void {}
};

pub fn runApp(log_dir_path: []const u8) *TuiApp {
    alloc.init();
    logger.init(log_dir_path);
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.terminal.enterAlternateScreen(writer) catch unreachable;
    ansi.cursor.hideCursorAndFlush(writer) catch unreachable;
    const context = tui_context.createTuiContext();
    const app_ptr = alloc.allocator().create((TuiApp)) catch {
        logger.logError("Out of memory");
        std.process.exit(1);
    };
    app_ptr.* = TuiApp.run(context);
    input.startListening();
    logger.logInfoFmt("TuiApp started", .{});
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
