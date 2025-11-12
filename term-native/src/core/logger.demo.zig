const std = @import("std");

// ----- 配置与对外常量 -----
pub const LOG_LEVEL = u8;
pub const LOG_LEVEL_DEBUG: u8 = 0;
pub const LOG_LEVEL_INFO: u8 = 1;
pub const LOG_LEVEL_WARNING: u8 = 2;
pub const LOG_LEVEL_ERROR: u8 = 3;

// 可调：缓冲大小与策略
const LOG_BUF_SIZE: usize = 1;
const FLUSH_ON_ERROR: bool = true; // error 级别是否即时 flush
const FILENAME_PREFIX: []const u8 = "term-bed-"; // daily: term-bed-YYYY-MM-DD.log

// ----- 全局状态（单线程）-----
var log_level: LOG_LEVEL = LOG_LEVEL_INFO;
var log_dir_path: []const u8 = undefined;
var initialized: bool = false;

// 长期持有的目录/文件/Writer 与缓冲
var g_dir: ?std.fs.Dir = null;
var g_file: ?std.fs.File = null;
var g_writer: ?std.fs.File.Writer = null;
var g_buf: [LOG_BUF_SIZE]u8 = undefined;

// 今日键（yyyymmdd），用于跨日旋转
var g_day_key: u32 = 0;

// ----- 对外：初始化 -----
pub fn setup(dir_path: []const u8, lvl: LOG_LEVEL) void {
    switch (lvl) {
        LOG_LEVEL_DEBUG...LOG_LEVEL_ERROR + 1 => log_level = lvl,
        else => {
            std.log.err("invalid log level", .{});
            std.process.exit(1);
        },
    }
    if (initialized) return;
    log_dir_path = dir_path;
    std.fs.makeDirAbsolute(log_dir_path) catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => ioError(),
    };
    openDirOrPanic();
    rotateIfNeededOrPanic(); // 初次打开当日文件
    initialized = true;
}

// ----- 对外：日志函数（签名不变）-----
pub fn logDebug(msg: []const u8) void {
    if (log_level > LOG_LEVEL_DEBUG) return;
    logWrite("{s} debug: {s}\n", .{ tsNow(), msg }, false);
}
pub fn logDebugFmt(comptime fmt: []const u8, args: anytype) void {
    if (log_level > LOG_LEVEL_DEBUG) return;
    logWrite("{s} debug: " ++ fmt ++ "\n", .{tsNow()} ++ args, false);
}
pub fn logInfo(msg: []const u8) void {
    if (log_level > LOG_LEVEL_INFO) return;
    logWrite("{s} info: {s}\n", .{ tsNow(), msg }, false);
}
pub fn logInfoFmt(comptime fmt: []const u8, args: anytype) void {
    if (log_level > LOG_LEVEL_DEBUG) return;
    logWrite("{s} info: " ++ fmt ++ "\n", .{tsNow()} ++ args, false);
}
pub fn logWarning(msg: []const u8) void {
    if (log_level > LOG_LEVEL_WARNING) return;
    logWrite("{s} warning: {s}\n", .{ tsNow(), msg }, false);
}
pub fn logWarningFmt(comptime fmt: []const u8, args: anytype) void {
    if (log_level > LOG_LEVEL_WARNING) return;
    logWrite("{s} warning: " ++ fmt ++ "\n", .{tsNow()} ++ args, false);
}
pub fn logError(msg: []const u8) void {
    if (log_level > LOG_LEVEL_ERROR) return;
    logWrite("{s} error: {s}\n", .{ tsNow(), msg }, FLUSH_ON_ERROR);
}
pub fn logErrorFmt(comptime fmt: []const u8, args: anytype) void {
    if (log_level > LOG_LEVEL_ERROR) return;
    logWrite("{s} error: " ++ fmt ++ "\n", .{tsNow()} ++ args, FLUSH_ON_ERROR);
}

// ----- 内部：热路径写入（零堆分配）-----
fn logWrite(comptime fmt: []const u8, args: anytype, flush_now: bool) void {
    if (!initialized) {
        std.log.err("logger not initialized", .{});
        std.process.exit(1);
    }
    rotateIfNeededOrPanic();
    var w = g_writer orelse unreachable;
    const io = &w.interface;
    io.print(fmt, args) catch ioError();
    if (flush_now) io.flush() catch ioError();
}

// ----- 内部：目录/文件/旋转 -----
fn openDirOrPanic() void {
    if (g_dir != null) return;
    g_dir = std.fs.openDirAbsolute(log_dir_path, .{}) catch ioError();
}
fn calcDayKeyAndName(buf: *[64]u8) struct { key: u32, name: []const u8 } {
    const now = std.time.timestamp();
    const epoch_seconds = @as(u64, @intCast(now));
    const epoch_day = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const yd = epoch_day.getEpochDay().calculateYearDay();
    const md = yd.calculateMonthDay();
    const year: u32 = yd.year;
    const mon: u32 = md.month.numeric();
    const day: u32 = md.day_index + 1;
    const key: u32 = year * 10000 + mon * 100 + day;
    const name = std.fmt.bufPrint(buf, "{s}{d:0>4}-{d:0>2}-{d:0>2}.log", .{ FILENAME_PREFIX, year, mon, day }) catch unreachable;
    return .{ .key = key, .name = name };
}
fn rotateIfNeededOrPanic() void {
    var name_buf: [64]u8 = undefined;
    const dn = calcDayKeyAndName(&name_buf);
    if (g_file != null and dn.key == g_day_key) return;
    if (g_writer) |*wr| {
        wr.interface.flush() catch {};
    }
    if (g_file) |*f| {
        f.close();
    }
    g_writer = null;
    g_file = null;
    var dir = g_dir orelse unreachable;
    var file = dir.createFile(dn.name, .{ .truncate = false }) catch ioError();
    file.seekFromEnd(0) catch ioError();
    // var writer =
    g_writer = file.writer(&g_buf);
    g_file = file;
    g_day_key = dn.key;
}

// ----- 内部：时间戳（零堆分配）-----
fn tsNow() []const u8 {
    var buf: [32]u8 = undefined;
    const now = std.time.timestamp();
    const epoch_seconds = @as(u64, @intCast(now));
    const epoch_day = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const ds = epoch_day.getDaySeconds();
    const yd = epoch_day.getEpochDay().calculateYearDay();
    const md = yd.calculateMonthDay();
    const year = yd.year;
    const mon = md.month.numeric();
    const day = md.day_index + 1;
    const h = ds.getHoursIntoDay();
    const m = ds.getMinutesIntoHour();
    const s = ds.getSecondsIntoMinute();
    const out = std.fmt.bufPrint(&buf, "[{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}]", .{ year, mon, day, h, m, s }) catch unreachable;
    return out;
}

// ----- 错误处理 -----
fn ioError() noreturn {
    std.log.err("IO error", .{});
    std.process.exit(1);
}
