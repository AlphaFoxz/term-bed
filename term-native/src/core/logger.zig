const std = @import("std");

var log_dir_path: []const u8 = undefined;
var log_path_init: bool = false;

pub fn init(dir_path: []const u8) void {
    if (log_path_init) {
        return;
    }
    log_dir_path = dir_path;
    log_path_init = true;
}

fn ioError() noreturn {
    std.log.err("IO error", .{});
    std.process.exit(1);
}

fn outOfMemory() noreturn {
    std.log.err("Out of memory", .{});
    std.process.exit(1);
}

fn currentTimstampStr(alloc: std.mem.Allocator) []const u8 {
    const timestamp = std.time.timestamp();
    // 转换为 epoch 秒并分解为日期时间
    const epoch_seconds = @as(u64, @intCast(timestamp));
    const epoch_day = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const day_seconds = epoch_day.getDaySeconds();
    const year_day = epoch_day.getEpochDay().calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    // 提取各个部分
    const year = year_day.year;
    const month = month_day.month.numeric();
    const day = month_day.day_index + 1;
    const hour = day_seconds.getHoursIntoDay();
    const minute = day_seconds.getMinutesIntoHour();
    const second = day_seconds.getSecondsIntoMinute();

    // 格式化输出
    const str = std.fmt.allocPrint(
        alloc,
        "[{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}]",
        .{ year, month, day, hour, minute, second },
    ) catch unreachable;
    return str;
}

fn write(msg: []const u8) void {
    if (!log_path_init) {
        return;
    }
    // std.fs.makeDirAbsolute(log_dir_path) catch unreachable;
    var dir = std.fs.openDirAbsolute(log_dir_path, .{}) catch {
        ioError();
    };
    defer dir.close();
    const file = dir.createFile("term-bed.log", .{
        .truncate = false,
        // .lock = .exclusive,
    }) catch {
        ioError();
    };
    defer file.close();
    file.seekFromEnd(0) catch {
        ioError();
    };
    var buffer: [256]u8 = undefined;
    var writer_inter = file.writerStreaming(&buffer);
    const writer = &writer_inter.interface;
    _ = writer.write(msg) catch {
        ioError();
    };
    writer.flush() catch {
        ioError();
    };
}

pub fn logDebug(msg: []const u8) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(alloc, "{s} debug: {s}\n", .{ timestamp, msg }) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}

pub fn logDebugFmt(comptime fmt: []const u8, args: anytype) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(
        alloc,
        "{s} debug: " ++ fmt ++ "\n",
        .{timestamp} ++ args,
    ) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}

pub fn logInfo(msg: []const u8) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(alloc, "{s} info: {s}\n", .{ timestamp, msg }) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}

pub fn logInfoFmt(comptime fmt: []const u8, args: anytype) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(
        alloc,
        "{s} info: " ++ fmt ++ "\n",
        .{timestamp} ++ args,
    ) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}

pub fn logWaring(msg: []const u8) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(alloc, "{s} warning: {s}\n", .{ timestamp, msg }) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}

pub fn logWaringFmt(comptime fmt: []const u8, args: anytype) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(
        alloc,
        "{s} warning: " ++ fmt ++ "\n",
        .{timestamp} ++ args,
    ) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}

pub fn logError(msg: []const u8) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(alloc, "{s} error: {s}\n", .{ timestamp, msg }) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}

pub fn logErrorFmt(comptime fmt: []const u8, args: anytype) void {
    const alloc = std.heap.page_allocator;
    const timestamp = currentTimstampStr(alloc);
    const str = std.fmt.allocPrint(
        alloc,
        "{s} error: " ++ fmt ++ "\n",
        .{timestamp} ++ args,
    ) catch {
        outOfMemory();
    };
    defer alloc.free(str);
    write(str);
}
