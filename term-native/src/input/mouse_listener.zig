const std = @import("std");
const windows = std.os.windows;
const logger = @import("../core/logger.zig");
const std_io = @import("../core/std_io.zig");

// 需要的常量定义
const ENABLE_MOUSE_INPUT = 0x0010;
const ENABLE_EXTENDED_FLAGS = 0x0080;
const MOUSE_EVENT = 0x0002;

const INPUT_RECORD = extern struct {
    EventType: u16,
    Event: extern union {
        KeyEvent: KEY_EVENT_RECORD,
        MouseEvent: MOUSE_EVENT_RECORD,
        WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
        MenuEvent: MENU_EVENT_RECORD,
        FocusEvent: FOCUS_EVENT_RECORD,
    },
};

const MOUSE_EVENT_RECORD = extern struct {
    dwMousePosition: COORD,
    dwButtonState: u32,
    dwControlKeyState: u32,
    dwEventFlags: u32,
};

const COORD = extern struct {
    X: i16,
    Y: i16,
};

// 其他事件类型（占位）
const KEY_EVENT_RECORD = extern struct { padding: [16]u8 };
const WINDOW_BUFFER_SIZE_RECORD = extern struct { padding: [4]u8 };
const MENU_EVENT_RECORD = extern struct { padding: [4]u8 };
const FOCUS_EVENT_RECORD = extern struct { padding: [4]u8 };

// 鼠标按钮状态
const FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001;
const RIGHTMOST_BUTTON_PRESSED = 0x0002;
const FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004;

// 鼠标事件标志
const MOUSE_MOVED = 0x0001;
const DOUBLE_CLICK = 0x0002;
const MOUSE_WHEELED = 0x0004;
const MOUSE_HWHEELED = 0x0008;

extern "kernel32" fn SetConsoleMode(
    hConsoleHandle: windows.HANDLE,
    dwMode: u32,
) callconv(.winapi) windows.BOOL;

extern "kernel32" fn GetConsoleMode(
    hConsoleHandle: windows.HANDLE,
    lpMode: *u32,
) callconv(.winapi) windows.BOOL;

extern "kernel32" fn ReadConsoleInputW(
    hConsoleInput: windows.HANDLE,
    lpBuffer: [*]INPUT_RECORD,
    nLength: u32,
    lpNumberOfEventsRead: *u32,
) callconv(.winapi) windows.BOOL;

var thread: std.Thread = undefined;
var thread_started: bool = false;
var should_stop = std.atomic.Value(bool).init(false);

pub fn start() void {
    if (!thread_started) {
        thread = std.Thread.spawn(.{}, listen, .{}) catch |e| {
            logger.logErrorFmt("Failed to start mouse event listener: {}", .{e});
            return;
        };
        thread_started = true;
    }
}

pub fn stop() void {
    if (thread_started) {
        should_stop.store(true, .release);
        thread.join();
        thread_started = false;
    }
}

fn listen() !void {
    // logger.logInfo("mouse event listener starting...");
    std.debug.print("mouse event listener starting...", .{});

    // const stdout = &std_io.writer.interface;
    const stdin_handle = windows.kernel32.GetStdHandle(@as(u32, @bitCast(@as(i32, -10)))).?;

    // 获取当前模式
    var original_mode: u32 = 0;
    _ = GetConsoleMode(stdin_handle, &original_mode);

    // 启用鼠标输入
    const new_mode = ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS;
    if (SetConsoleMode(stdin_handle, new_mode) == 0) {
        std.debug.print("Failed to enable mouse input.", .{});
        return;
    }

    defer _ = SetConsoleMode(stdin_handle, original_mode); // 恢复原始模式

    var input_buffer: [128]INPUT_RECORD = undefined;
    var events_read: u32 = 0;

    while (!should_stop.load(.acquire)) {
        if (ReadConsoleInputW(stdin_handle, &input_buffer, 1, &events_read) == 0) {
            break;
        }

        if (events_read > 0) {
            const record = input_buffer[0];

            if (record.EventType == MOUSE_EVENT) {
                const mouse = record.Event.MouseEvent;

                // 检测按钮点击
                if (mouse.dwButtonState & FROM_LEFT_1ST_BUTTON_PRESSED != 0) {
                    // logger.logInfoFmt("mouse left click: ({}, {})\n", .{
                    std.debug.print("mouse left click: ({}, {})\n", .{
                        mouse.dwMousePosition.X,
                        mouse.dwMousePosition.Y,
                    });
                }

                if (mouse.dwButtonState & RIGHTMOST_BUTTON_PRESSED != 0) {
                    // logger.logInfoFmt("mouse right click: ({}, {})\n", .{
                    std.debug.print("mouse right click: ({}, {})\n", .{
                        mouse.dwMousePosition.X,
                        mouse.dwMousePosition.Y,
                    });
                }

                if (mouse.dwButtonState & FROM_LEFT_2ND_BUTTON_PRESSED != 0) {
                    // logger.logInfoFmt("mouse middle click: ({}, {})\n", .{
                    std.debug.print("mouse middle click: ({}, {})\n", .{
                        mouse.dwMousePosition.X,
                        mouse.dwMousePosition.Y,
                    });
                }

                // 检测鼠标移动
                if (mouse.dwEventFlags & MOUSE_MOVED != 0 and mouse.dwButtonState == 0) {
                    // try stdout.print("mouse move: ({}, {})\n", .{
                    //     mouse.dwMousePosition.X,
                    //     mouse.dwMousePosition.Y,
                    // });
                }

                // 检测双击
                if (mouse.dwEventFlags & DOUBLE_CLICK != 0) {
                    // logger.logInfoFmt("mouse double click: ({}, {})\n", .{
                    std.debug.print("mouse double click: ({}, {})\n", .{
                        mouse.dwMousePosition.X,
                        mouse.dwMousePosition.Y,
                    });
                }

                // 检测滚轮
                if (mouse.dwEventFlags & MOUSE_WHEELED != 0) {
                    const delta = @as(i32, @bitCast(mouse.dwButtonState)) >> 16;
                    const direction = if (delta > 0) "up" else "down";
                    // logger.logInfoFmt("mouse wheel {s}: ({}, {})\n", .{
                    std.debug.print("mouse wheel {s}: ({}, {})\n", .{
                        direction,
                        mouse.dwMousePosition.X,
                        mouse.dwMousePosition.Y,
                    });
                }
            }
        }
    }
}

test "mouse event listener" {
    start();
    std.Thread.sleep(10_000_000);
    stop();
}
