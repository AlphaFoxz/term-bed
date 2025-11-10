const std = @import("std");
const builtin = @import("builtin");
const logger = @import("./core/logger.zig");

pub const mouse_listener = @import("./input/mouse_listener.zig");
pub const key_listener = @import("./input/key_listener.zig");

pub fn startListening() void {
    setRawMode(true);
    logger.logInfo("Raw mode set to true");
    key_listener.start();
    mouse_listener.start();
}

pub fn stopListening() void {
    setRawMode(false);
    logger.logInfo("Raw mode set to false");
    key_listener.stop();
    mouse_listener.stop();
}

fn rawModeError() noreturn {
    logger.logError("Failed to set raw mode");
    std.process.exit(1);
}

/// 跨平台的终端原始模式实现
pub fn setRawMode(enable: bool) void {
    switch (builtin.os.tag) {
        .windows => setRawModeWindows(enable) catch {
            logger.logError("setRawModeWindows failed");
            rawModeError();
        },
        .linux, .macos, .freebsd, .netbsd, .openbsd => setRawModePosix(enable) catch {
            logger.logError("setRawModePosix failed");
            rawModeError();
        },
        else => return error.UnsupportedOS,
    }
}

/// Windows 系统的实现
fn setRawModeWindows(enable: bool) !void {
    const windows = std.os.windows;

    // Windows Console Mode 常量
    const ENABLE_LINE_INPUT = 0x0002;
    const ENABLE_ECHO_INPUT = 0x0004;
    const ENABLE_PROCESSED_INPUT = 0x0001;
    const ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;

    // 获取当前控制台模式
    var mode: windows.DWORD = 0;
    const stdin_handle = windows.kernel32.GetStdHandle(@as(u32, @bitCast(@as(i32, -10)))).?;
    if (windows.kernel32.GetConsoleMode(stdin_handle, &mode) == 0) {
        logger.logErrorFmt("Failed to get console mode: {any}", .{windows.kernel32.GetLastError()});
        return error.GetConsoleModeFailure;
    }

    if (enable) {
        // 禁用行输入模式（逐字符读取）
        mode &= ~@as(windows.DWORD, ENABLE_LINE_INPUT);

        // 禁用回显
        mode &= ~@as(windows.DWORD, ENABLE_ECHO_INPUT);

        // 禁用 Ctrl+C 等特殊处理
        mode &= ~@as(windows.DWORD, ENABLE_PROCESSED_INPUT);

        // 启用虚拟终端输入（支持 ANSI 转义序列）
        mode |= ENABLE_VIRTUAL_TERMINAL_INPUT;
    } else {
        // 恢复正常模式
        mode |= ENABLE_LINE_INPUT;
        mode |= ENABLE_ECHO_INPUT;
        mode |= ENABLE_PROCESSED_INPUT;
    }

    // 设置控制台模式
    if (windows.kernel32.SetConsoleMode(stdin_handle, mode) == 0) {
        return error.SetConsoleModeFailure;
    }
}

/// POSIX 系统（Linux, macOS 等）的实现
fn setRawModePosix(enable: bool) !void {
    const stdin_handle = std.posix.STDIN_FILENO;

    // 获取当前终端属性
    var termios = try std.posix.tcgetattr(stdin_handle);

    if (enable) {
        // 进入原始模式

        // 禁用规范模式 - 不等待回车
        termios.lflag.ICANON = false;

        // 禁用回显
        termios.lflag.ECHO = false;

        // 禁用信号字符处理 (Ctrl+C, Ctrl+Z 等)
        termios.lflag.ISIG = false;

        // 禁用输入处理
        termios.iflag.IXON = false; // 禁用 XON/XOFF 流控制
        termios.iflag.ICRNL = false; // 禁用 CR 转 NL
        termios.iflag.BRKINT = false; // 禁用 break 信号
        termios.iflag.INPCK = false; // 禁用奇偶校验
        termios.iflag.ISTRIP = false; // 禁用第8位剥离

        // 禁用输出处理
        termios.oflag.OPOST = false;

        // 设置字符大小为8位
        termios.cflag.CSIZE = .CS8;

        // 设置最小读取字符数和超时
        termios.cc[@intFromEnum(std.posix.V.MIN)] = 0; // 非阻塞读取
        termios.cc[@intFromEnum(std.posix.V.TIME)] = 0; // 无超时
    } else {
        // 恢复为正常模式
        termios.lflag.ICANON = true;
        termios.lflag.ECHO = true;
        termios.lflag.ISIG = true;
        termios.iflag.IXON = true;
        termios.iflag.ICRNL = true;
        termios.oflag.OPOST = true;
    }

    // 应用设置 (立即生效)
    try std.posix.tcsetattr(stdin_handle, .NOW, termios);
}
