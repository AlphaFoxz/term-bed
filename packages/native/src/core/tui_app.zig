const std = @import("std");
const Io = std.Io;
const tui_context = @import("./tui_context.zig");
const ansi = @import("../ansi_util.zig");
const std_io = @import("./std_io.zig");
const glo_alloc = @import("./glo_alloc.zig");
const input = @import("../input.zig");
const logger = @import("./logger.zig");
const event_bus = @import("./event_bus.zig");
const Rgba = @import("../ansi_util/style.zig").Rgba;
const err = @import("./error.zig");
const wdt_common = @import("./widgets/common.zig");

pub const Scene = struct {
    alloc: std.mem.Allocator,
    id: u64,
    visible: bool,
    background_color: Rgba,

    pub fn init(visible: bool, background_color: Rgba) *Scene {
        const alloc = glo_alloc.allocator();
        const ptr = alloc.create(Scene) catch {
            err.outOfMemory();
        };
        ptr.* = Scene{
            .alloc = alloc,
            .id = wdt_common.genId(),
            .visible = visible,
            .background_color = background_color,
        };
        return ptr;
    }

    pub fn deinit(self: *Scene) void {
        defer self.alloc.destroy(self);
    }
};

pub const TuiApp = struct {
    alloc: std.mem.Allocator,
    context: *tui_context.TuiContext,

    pub fn init(context: *tui_context.TuiContext) *TuiApp {
        const alloc = glo_alloc.allocator();
        const tui_app = alloc.create((TuiApp)) catch {
            logger.logError("Out of memory");
            std.process.exit(1);
        };
        tui_app.* = TuiApp{
            .alloc = alloc,
            .context = context,
        };
        return tui_app;
    }
    pub fn deinit(self: *TuiApp) void {
        defer self.alloc.destroy(self);
        self.context.deinit();
    }
};

pub fn createApp() *TuiApp {
    std_io.init();
    event_bus.event_bus_setup();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.terminal.enterAlternateScreen(writer) catch unreachable;
    ansi.cursor.hideCursorAndFlush(writer) catch unreachable;
    const context = tui_context.TuiContext.init(glo_alloc.allocator());
    const app_ptr = TuiApp.init(context);
    input.startListening();
    logger.logInfo("TuiApp created");
    return app_ptr;
}

pub fn destroyApp(app: *TuiApp) void {
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.cursor.showCursor(writer) catch unreachable;
    ansi.terminal.leaveAlternateScreen(writer) catch unreachable;
    input.stopListening();
    app.deinit();
    ansi.clear.clearScreenAndFlush(writer) catch unreachable;
    std_io.flushAll();
    logger.logWarning("TuiApp destroyed");
}
