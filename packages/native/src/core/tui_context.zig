const std = @import("std");
const builtin = @import("builtin");
const std_io = @import("./std_io.zig");
const logger = @import("./logger.zig");
const err = @import("./error.zig");
const glo_alloc = @import("./glo_alloc.zig");

const TuiScale = u16;

pub const TuiContext = struct {
    alloc: std.mem.Allocator,
    screen_rect: TuiRect,

    pub fn init(alloc: std.mem.Allocator) *TuiContext {
        const ptr = alloc.create(TuiContext) catch {
            err.outOfMemory();
        };
        ptr.* = TuiContext{
            .alloc = alloc,
            .screen_rect = detectScreenRect(),
        };
        return ptr;
    }

    pub fn deinit(self: *TuiContext) void {
        defer self.alloc.destroy(self);
    }
};

pub const TuiRect = struct {
    x: TuiScale,
    y: TuiScale,
    rows: TuiScale,
    cols: TuiScale,
};

fn detectScreenRect() TuiRect {
    var screen_rect = TuiRect{
        .x = 0,
        .y = 0,
        .rows = 35,
        .cols = 90,
    };
    const fd = std.fs.File.stdout().handle;
    if (builtin.os.tag == .windows) {
        const windows = std.os.windows;
        var info: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
        if (windows.kernel32.GetConsoleScreenBufferInfo(fd, &info) != windows.TRUE) {
            logger.logError("windows.kernel32 cannot GetConsoleScreenBufferInfo");
            return screen_rect;
        } else {
            logger.logInfoFmt("detected console srWindow info [Top: {d} Right: {d} Bottom: {d} Left: {d}]", .{
                info.srWindow.Top,
                info.srWindow.Right,
                info.srWindow.Bottom,
                info.srWindow.Left,
            });
            logger.logInfoFmt("detected console dwSize info [X: {d} Y: {d}]", .{
                info.dwSize.X,
                info.dwSize.Y,
            });
            screen_rect.cols = @intCast(info.srWindow.Right + 1);
            screen_rect.rows = @intCast(info.srWindow.Bottom + 1);
        }
    } else {
        const posix = std.posix;
        var winsize: posix.winsize = .{
            .row = 0,
            .col = 0,
            .xpixel = 0,
            .ypixel = 0,
        };
        const errno = posix.system.ioctl(fd, posix.T.IOCGWINSZ, @intFromPtr(&winsize));
        if (posix.errno(errno) == .SUCCESS) {
            screen_rect.cols = winsize.col;
            screen_rect.rows = winsize.row;
        } else {
            logger.logError("posix cannot ioctl");
            return screen_rect;
        }
    }
    return screen_rect;
}

test "screen_rect" {
    const testing = std.testing;
    const rect = detectScreenRect();
    try testing.expect(rect.cols > 10);
    try testing.expect(rect.rows > 10);
}
