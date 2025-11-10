const std = @import("std");

pub const LogLevel = enum {
    debug,
    info,
    warning,
    @"error",
};

pub const LogEvent = struct {
    level: LogLevel,
    content: []const u8,
    pub fn fromConst() LogEvent {
        return LogEvent{};
    }
};

var js_logger: ?*const fn ([*c]const u8) callconv(.c) void = null;

pub fn init(cb: *const fn ([*c]const u8) callconv(.c) void) void {
    js_logger = cb;
}

pub fn logDebug(comptime str: []const u8) void {
    if (js_logger) |cb| {
        cb("debug: " ++ str);
    }
}

pub fn logDebugFmt(comptime fmt: []const u8, args: anytype) void {
    if (js_logger) |cb| {
        var buf: [4096]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, "debug: " ++ fmt, args) catch {
            cb("debug: [formatting failed]");
            return;
        };
        cb(msg);
    }
}

pub fn logInfo(comptime str: []const u8) void {
    if (js_logger) |cb| {
        cb("info: " ++ str);
    }
}

pub fn logInfoFmt(comptime fmt: []const u8, args: anytype) void {
    if (js_logger) |cb| {
        var buf: [4096]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, "info: " ++ fmt, args) catch {
            cb("info: [formatting failed]");
            return;
        };
        cb(msg);
    }
}

pub fn logWarning(comptime str: []const u8) void {
    if (js_logger) |cb| {
        cb("warning: " ++ str);
    }
}

pub fn logWarningFmt(comptime fmt: []const u8, args: anytype) void {
    if (js_logger) |cb| {
        var buf: [4096]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, "warning: " ++ fmt, args) catch {
            cb("warning: [formatting failed]");
            return;
        };
        cb(msg);
    }
}

pub fn logError(comptime str: []const u8) void {
    if (js_logger) |cb| {
        cb("error: " ++ str);
    }
}

pub fn logErrorFmt(comptime fmt: []const u8, args: anytype) void {
    if (js_logger) |cb| {
        var buf: [4096]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, "error: " ++ fmt, args) catch {
            cb("error: [formatting failed]");
            return;
        };
        cb(msg);
    }
}
