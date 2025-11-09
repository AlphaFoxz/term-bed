const std = @import("std");
const tui_context = @import("./tui_context.zig");
const ansi = @import("../ansi_util/index.zig");
const std_io = @import("./std_io.zig");
const alloc = @import("./alloc.zig");

var jsLogger: ?*const fn ([*c]const u8) callconv(.C) void = null;

pub fn logErr(comptime str: []const u8) void {
    if (jsLogger) |cb| {
        cb("error: " ++ str);
    }
}

pub fn logInfo(comptime str: []const u8) void {
    if (jsLogger) |cb| {
        cb("info: " ++ str);
    }
}

pub const TuiApp = struct {
    context: tui_context.TuiContext,

    pub fn run(ctx: tui_context.TuiContext) TuiApp {
        const app = TuiApp{ .context = ctx };
        return app;
    }

    pub fn exit(_: @This()) void {}
};

pub fn runApp(logger: *const fn ([*c]const u8) callconv(.C) void) *TuiApp {
    alloc.init();
    jsLogger = logger;
    const writer = std_io.getStdWriter();
    ansi.terminal.enterAlternateScreen(writer) catch unreachable;
    ansi.cursor.hideCursor(writer) catch unreachable;
    const tuiContext = tui_context.TuiContext{};
    const appPtr = alloc.allocator().create((TuiApp)) catch {
        const msg = "Out of memory";
        logErr(msg);
        std.process.exit(1);
    };
    appPtr.* = TuiApp.run(tuiContext);
    logInfo("TuiApp created");
    return appPtr;
}

pub fn exitApp(appApr: *TuiApp) void {
    const writer = std_io.getStdWriter();
    ansi.cursor.showCursor(writer) catch unreachable;
    ansi.terminal.leaveAlternateScreen(writer) catch unreachable;
    appApr.exit();
    alloc.allocator().destroy(appApr);
    alloc.deinit();
}
