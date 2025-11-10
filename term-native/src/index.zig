const std = @import("std");
const Io = std.Io;
const std_io = @import("./core/std_io.zig");
const String = @import("./core/string.zig").String;
const widgets = @import("./core/widgets.zig");
const ansi = @import("./ansi_util.zig");
const tui_app = @import("./core/tui_app.zig");
const render = @import("./render.zig");
const alloc = @import("./core/alloc.zig");

// ======================== app ========================
pub export fn runApp(cdir_path: [*:0]const u8) *tui_app.TuiApp {
    alloc.init();
    const dir_path = alloc.allocator().dupe(u8, std.mem.span(cdir_path)) catch {
        std.log.err("Out of memory", .{});
        std.process.exit(1);
    };
    return tui_app.runApp(dir_path);
}

pub export fn exitApp(app: *tui_app.TuiApp) void {
    tui_app.exitApp(app);
}

pub export fn renderApp() void {}

pub export fn forceRenderApp(app_ptr: *tui_app.TuiApp) void {
    render.forceRenderApp(app_ptr);
}

// ======================== widgets =======================
pub export fn createTextWidget(x: u16, y: u16, width: u16, height: u16, cstr: [*:0]const u8) *widgets.text.Text {
    const text = String.fromCString(cstr);
    return widgets.text.createText(x, y, width, height, text);
}

pub export fn destroyWidget(widget_ptr: ?*widgets.Widget) void {
    if (widget_ptr == null) {} else {
        widgets.destroyWidget(widget_ptr.?);
    }
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

pub export fn drawText(x: u16, y: u16, cstr: [*:0]const u8) void {
    const s = std.mem.span(cstr);
    std_io.init();
    const writer: *Io.Writer = &std_io.writer.interface;
    ansi.printAndFlush(writer, "\x1b[{d};{d}H{s}", .{ y + 1, x + 1, s }) catch unreachable;
}
