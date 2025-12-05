const std = @import("std");
const Io = std.Io;
const std_io = @import("./core/std_io.zig");
const String = @import("./core/string.zig").String;
const widgets = @import("./core/widgets.zig");
const ansi = @import("./ansi_util.zig");
const tui_app = @import("./core/tui_app.zig");
const render = @import("./render.zig");
const glo_alloc = @import("./core/glo_alloc.zig");
const logger = @import("./core/logger.zig");
const event_bus = @import("./core/event_bus.zig");

// ======================== app ========================
pub export fn setupLogger(
    cdir_path: [*:0]const u8,
    clog_name: [*:0]const u8,
    log_level: logger.LOG_LEVEL,
) void {
    const alloc = glo_alloc.allocator();
    const dir_path = alloc.dupe(u8, std.mem.span(cdir_path)) catch {
        std.log.err("Out of memory", .{});
        std.process.exit(1);
    };
    const log_name = alloc.dupe(u8, std.mem.span(clog_name)) catch {
        std.log.err("Out of memory", .{});
        std.process.exit(1);
    };
    return logger.load(dir_path, log_name, log_level);
}

pub export fn createApp() *tui_app.TuiApp {
    return tui_app.createApp();
}

pub export fn destroyApp(app: *tui_app.TuiApp) void {
    tui_app.destroyApp(app);
}

pub export fn renderApp() void {}

pub export fn forceRenderApp(app_ptr: *tui_app.TuiApp) void {
    render.forceRenderApp(app_ptr);
}

// ======================== event ========================
pub export fn event_bus_setup() void {
    event_bus.event_bus_setup();
}

// 发布事件：event_type, data指针, 长度
pub export fn event_bus_emit(event_type: u16, data_ptr: [*]const u8, len: usize) c_int {
    return event_bus.event_bus_emit(event_type, data_ptr, len);
}

pub export fn event_bus_poll() ?*const event_bus.EventSlot {
    return event_bus.event_bus_poll();
}

// 确认读取
pub export fn event_bus_commit() void {
    event_bus.event_bus_commit();
}

// 获取队列统计
pub export fn event_bus_stats(out_pending: *u64) void {
    event_bus.event_bus_stats(out_pending);
}

// ======================== widgets =======================
pub export fn createSceneWidget(visible: bool, bg_hex_rgb: u32) *widgets.Widget {
    var w: widgets.Widget = .{ .scene = widgets.scene.Scene.init(visible, ansi.style.Rgba.fromU32((bg_hex_rgb << 8) + 100)) };
    return &w;
}

pub export fn createTextWidget(x: u16, y: u16, width: u16, height: u16, visible: bool, cstr: [*:0]const u8) *widgets.Widget {
    const text = String.initFromCSclice(cstr);
    var w: widgets.Widget = .{ .text = widgets.text.Text.init(x, y, width, height, visible, text) };
    return &w;
}

pub export fn destroyWidget(widget_ptr: ?*widgets.Widget) void {
    if (widget_ptr == null) {} else {
        widget_ptr.?.deinit();
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
