const tui_app = @import("./core/tui_app.zig");

pub export fn runApp(logger: *const fn ([*c]const u8) callconv(.C) void) *tui_app.TuiApp {
    return tui_app.runApp(logger);
}

pub export fn exitApp(app: *tui_app.TuiApp) void {
    tui_app.exitApp(app);
}
