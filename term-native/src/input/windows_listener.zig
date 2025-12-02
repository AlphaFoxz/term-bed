const std = @import("std");
const logger = @import("../core/logger.zig");
const windows = std.os.windows;
const mode = @import("./mode.zig");
const event_bus = @import("../core/event_bus.zig");

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

// =================== Windows Impl ===================
pub const KEY_EVENT_RECORD = extern struct {
    bKeyDown: windows.BOOL,
    wRepeatCount: u16,
    wVirtualKeyCode: u16,
    wVirtualScanCode: u16,
    uChar: extern union {
        UnicodeChar: u16,
        AsciiChar: windows.CHAR,
    },
    dwControlKeyState: u32,
};
pub const MOUSE_EVENT_RECORD = extern struct {
    dwMousePosition: windows.COORD,
    dwButtonState: u32,
    dwControlKeyState: u32,
    dwEventFlags: u32,
};
pub const WINDOW_BUFFER_SIZE_RECORD = extern struct {
    dwSize: windows.COORD,
};
pub const MENU_EVENT_RECORD = extern struct {
    dwCommandId: u32,
};

pub const FOCUS_EVENT_RECORD = extern struct {
    bSetFocus: windows.BOOL,
};
pub const INPUT_RECORD = extern struct {
    EventType: u16,
    Event: extern union {
        KeyEvent: KEY_EVENT_RECORD,
        MouseEvent: MOUSE_EVENT_RECORD,
        WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
        MenuEvent: MENU_EVENT_RECORD,
        FocusEvent: FOCUS_EVENT_RECORD,
    },
};

pub extern "kernel32" fn ReadConsoleInputW(
    hConsoleInput: ?windows.HANDLE,
    lpBuffer: [*]INPUT_RECORD,
    nLength: u32,
    lpNumberOfEventsRead: ?*u32,
) callconv(.winapi) windows.BOOL;

pub extern "kernel32" fn WaitForSingleObject(
    hHandle: ?windows.HANDLE,
    dwMilliseconds: u32,
) callconv(.winapi) u32;

// 鼠标按钮状态
const FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001;
const RIGHTMOST_BUTTON_PRESSED = 0x0002;
const FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004;

// 鼠标事件标志
const MOUSE_MOVED = 0x0001;
const DOUBLE_CLICK = 0x0002;
const MOUSE_WHEELED = 0x0004;
// const MOUSE_HWHEELED = 0x0008;

// 定义简单的状态机状态
const InputState = enum {
    Normal,
    EscReceived, // 收到了 \x1b
    CsiReceived, // 收到了 [
    // 实际的 parser 可能会更复杂，这里简化演示
};

const Parser = struct {
    state: InputState = .Normal,
    buffer: [64]u8 = undefined,
    buf_idx: usize = 0,

    pub fn processEvent(self: *Parser, record: KEY_EVENT_RECORD) void {
        // 1. 过滤掉按键释放事件 (通常 TUI 不需要处理 KeyUp)
        if (record.bKeyDown == 0) return;

        const char_code = record.uChar.UnicodeChar;

        // ---------------------------------------------------------
        // 情况 A: 汉字 / Unicode 字符
        // ---------------------------------------------------------
        // Windows 使用 UTF-16 (u16)，大部分汉字在这个范围内
        // 如果是 Emoji 等辅助平面字符，可能需要处理两个连续的 Event (Surrogate Pairs)
        if (char_code > 0xFF) { // 大于 255 基本上就是宽字符了
            logger.logDebugFmt("汉字/Unicode输入: {u} (Code: {d})", .{ char_code, char_code });
            self.reset();
            return;
        }

        const ascii: u8 = @intCast(char_code);

        // ---------------------------------------------------------
        // 情况 B: 鼠标事件 / ANSI 序列处理 (状态机)
        // ---------------------------------------------------------
        switch (self.state) {
            .Normal => {
                if (ascii == 0x1B) { // ESC 键
                    self.state = .EscReceived;
                    self.buf_idx = 0;
                    self.buffer[self.buf_idx] = ascii;
                    self.buf_idx += 1;
                } else {
                    // 普通 ASCII 字符
                    self.handleNormalKey(record);
                }
            },
            .EscReceived => {
                // 如果紧接着 ESC 收到的是 '[' (0x5B)，说明是 CSI 序列 (可能是鼠标，也可能是方向键)
                if (ascii == '[') {
                    self.state = .CsiReceived;
                    self.buffer[self.buf_idx] = ascii;
                    self.buf_idx += 1;
                } else {
                    // 如果 ESC 后面跟的不是 [，那说明用户就是按了一下 ESC，然后按了别的键
                    // 处理之前的 ESC
                    logger.logDebug("按键: ESC");
                    self.reset();
                    // 重新处理当前这个字符
                    self.processEvent(record);
                }
            },
            .CsiReceived => {
                // 这里开始收集序列参数，例如: \x1b[<0;23;45M
                self.buffer[self.buf_idx] = ascii;
                self.buf_idx += 1;

                // 判断序列结束字符
                // 鼠标 VT 序列通常以 'M' (按下) 或 'm' (释放) 结尾
                // 普通功能键通常以 '~' 或 字母(A-Z) 结尾
                if ((ascii >= 'A' and ascii <= 'Z') or (ascii >= 'a' and ascii <= 'z') or ascii == '~') {
                    self.parseSequence();
                    self.reset();
                }
            },
        }
    }

    fn handleNormalKey(_: *Parser, record: KEY_EVENT_RECORD) void {
        var unicode_char = record.uChar.UnicodeChar;
        const virtual_code = record.wVirtualKeyCode;
        var buf: [64]u8 = undefined;
        var slice: []u8 = undefined;

        if (unicode_char == 0) {
            unicode_char = record.wVirtualKeyCode;
            logger.logDebugFmt("特殊键 (VirtualKey: {})", .{unicode_char});
            // 情况 1: 特殊键 (F1, Home, Arrow, etc.)
            // char 字段设为 null，只传 code
            logger.logDebugFmt("特殊键: {}", .{virtual_code});
            slice = std.fmt.bufPrint(&buf,
                \\{{"char":null,"code":{d}}}
            , .{virtual_code}) catch unreachable;
        } else if (unicode_char < 32) {
            logger.logDebugFmt("控制字符 (Ctrl+Key): {}", .{unicode_char});
            slice = std.fmt.bufPrint(&buf,
                \\{{"char":null,"code":{d}}}
            , .{unicode_char}) catch unreachable;
        } else {
            logger.logDebugFmt("普通字符: {u}", .{unicode_char});
            slice = std.fmt.bufPrint(&buf,
                \\{{"char":"{u}","code":{d}}}
            , .{ unicode_char, unicode_char }) catch unreachable;
        }

        _ = event_bus.event_bus_emit_bytes(
            @intFromEnum(event_bus.EventType.KeyEvent),
            slice,
        );
    }

    fn bak(_: *Parser, record: KEY_EVENT_RECORD) void {
        const unicode_char = record.uChar.UnicodeChar;
        const virtual_code = record.wVirtualKeyCode;
        var buf: [64]u8 = undefined;
        var slice: []u8 = undefined;

        if (unicode_char == 0) {
            // 情况 1: 特殊键 (F1, Home, Arrow, etc.)
            // char 字段设为 null，只传 code
            logger.logDebugFmt("特殊键: {}", .{virtual_code});
            slice = std.fmt.bufPrint(&buf,
                \\{{"char":null,"code":{d}}}
            , .{virtual_code}) catch unreachable;
        } else {
            // 情况 2: 有字符输入 (包括 a, A, 1, Enter, Backspace)
            // 必须处理转义，为了简单起见，建议对于特殊符号只传 code，不传 char 文本
            // 或者简单的转义判断：
            if (unicode_char == '"') {
                // 手动转义双引号
                slice = std.fmt.bufPrint(&buf,
                    \\{{"char":"\"","code":{d}}}
                , .{unicode_char}) catch unreachable;
            } else if (unicode_char == '\\') {
                // 手动转义反斜杠
                slice = std.fmt.bufPrint(&buf,
                    \\{{"char":"\\","code":{d}}}
                , .{unicode_char}) catch unreachable;
            } else if (unicode_char < 32) {
                // 控制字符 (如回车)，只发 code，char 为 null 避免 JSON 错误
                // 或者前端靠 code 13 来判断回车
                slice = std.fmt.bufPrint(&buf,
                    \\{{"char":null,"code":{d}}}
                , .{unicode_char}) catch unreachable;
            } else {
                // 普通可见字符
                logger.logDebugFmt("字符: {u}", .{unicode_char});
                slice = std.fmt.bufPrint(&buf,
                    \\{{"char":"{u}","code":{d}}}
                , .{ unicode_char, unicode_char }) catch unreachable;
            }
        }
    }

    fn parseSequence(self: *Parser) void {
        const seq = self.buffer[0..self.buf_idx];

        // 简单的判断演示
        if (std.mem.startsWith(u8, seq, "\x1b[<")) {
            // 这是一个 SGR 鼠标模式序列: \x1b[<b;x;yM
            if (seq.len < 6) return;
            const content = seq[3 .. seq.len - 1];
            const is_release = seq[seq.len - 1] == 'm'; // 'M' (按下/移动) 或 'm' (松开)

            var iter = std.mem.splitScalar(u8, content, ';');
            const pb_str = iter.next() orelse return;
            const px_str = iter.next() orelse return;
            const py_str = iter.next() orelse return;

            var pb = std.fmt.parseInt(u8, pb_str, 10) catch return;
            const px = std.fmt.parseInt(u16, px_str, 10) catch return;
            const py = std.fmt.parseInt(u16, py_str, 10) catch return;
            const is_shift = (pb & 0x04) != 0;
            if (is_shift) {
                pb ^= 0x04;
            }
            const is_alt = (pb & 0x08) != 0;
            if (is_alt) {
                pb ^= 0x08;
            }
            const is_ctrl = (pb & 0x10) != 0;
            if (is_ctrl) {
                pb ^= 0x10;
            }
            const is_drag = (pb & 0x20) != 0;
            if (is_drag) {
                pb ^= 0x20;
            }

            switch (pb) {
                0 => {
                    logger.logDebugFmt("鼠标左键{s}，x: {}, y: {}", .{
                        if (is_release) "释放" else "按下",
                        px,
                        py,
                    });
                },
                1 => {
                    logger.logDebugFmt("鼠标中键{s}，x: {}, y: {}", .{
                        if (is_release) "释放" else "按下",
                        px,
                        py,
                    });
                },
                2 => {
                    logger.logDebugFmt("鼠标右键{s}，x: {}, y: {}", .{
                        if (is_release) "释放" else "按下",
                        px,
                        py,
                    });
                },
                3 => {
                    logger.logDebugFmt("鼠标移动，x: {}, y: {}", .{ px, py });
                },
                64 => {
                    logger.logDebugFmt("鼠标滚轮上，x: {}, y: {}", .{ px, py });
                },
                65 => {
                    logger.logDebugFmt("鼠标滚轮下，x: {}, y: {}", .{ px, py });
                },
                else => {
                    logger.logWarningFmt("不支持的鼠标事件序列，pb: {}, x: {}, y: {}", .{ pb, px, py });
                },
            }
        } else if (std.mem.eql(u8, seq, "\x1b[A")) {
            logger.logDebugFmt("方向键: UP", .{});
        } else {
            logger.logDebugFmt("其他 ANSI 序列: {x}", .{seq});
        }
    }

    fn reset(self: *Parser) void {
        self.state = .Normal;
        self.buf_idx = 0;
    }
};

fn listen() void {
    logger.logInfo("input listener starting...");
    const stdin_handle = windows.kernel32.GetStdHandle(@intFromEnum(mode.STD_HANDLE.INPUT_HANDLE)).?;

    // const FOCUS_EVENT = 0x0010;
    const KEY_EVENT = 0x0001;
    // const MENU_EVENT = 0x0008;
    const MOUSE_EVENT = 0x0002;
    // const WINDOW_BUFFER_SIZE_EVENT = 0x0004;

    // 获取当前模式
    mode.switchMouseInputMode();

    while (!should_stop.load(.acquire)) {
        const waitResult = WaitForSingleObject(stdin_handle, 16);
        if (waitResult != windows.WAIT_OBJECT_0) {
            continue;
        }
        var input_buffer: [128]INPUT_RECORD = undefined;
        var events_read: u32 = 0;
        if (ReadConsoleInputW(
            stdin_handle,
            &input_buffer,
            128,
            &events_read,
        ) == 0) {
            logger.logError("ReadConsoleInputEx failed");
            break;
        }

        for (0..events_read) |i| {
            const record = input_buffer[i];
            if (record.EventType == MOUSE_EVENT) {
                handleMouseEvent(record);
            } else if (record.EventType == KEY_EVENT) {
                handleKeyEvent(record);
            }
        }
        logger.flush();
    }
}

inline fn handleMouseEvent(record: INPUT_RECORD) void {
    const mouse = record.Event.MouseEvent;
    var handle_flag = false;

    // 检测按钮点击
    if (mouse.dwButtonState & FROM_LEFT_1ST_BUTTON_PRESSED != 0) {
        logger.logDebugFmt("mouse left click: ({}, {})", .{
            mouse.dwMousePosition.X,
            mouse.dwMousePosition.Y,
        });
        handle_flag = true;
    }

    if (mouse.dwButtonState & RIGHTMOST_BUTTON_PRESSED != 0) {
        logger.logDebugFmt("mouse right click: ({}, {})", .{
            mouse.dwMousePosition.X,
            mouse.dwMousePosition.Y,
        });
        handle_flag = true;
    }

    if (mouse.dwButtonState & FROM_LEFT_2ND_BUTTON_PRESSED != 0) {
        logger.logDebugFmt("mouse middle click: ({}, {})", .{
            mouse.dwMousePosition.X,
            mouse.dwMousePosition.Y,
        });
        handle_flag = true;
    }

    // 检测鼠标移动
    if (mouse.dwEventFlags & MOUSE_MOVED != 0 and mouse.dwButtonState == 0) {
        // try stdout.print("mouse move: ({}, {})\n", .{
        //     mouse.dwMousePosition.X,
        //     mouse.dwMousePosition.Y,
        // });
        handle_flag = true;
    }

    // 检测双击
    if (mouse.dwEventFlags & DOUBLE_CLICK != 0) {
        logger.logDebugFmt("mouse double click: ({}, {})", .{
            mouse.dwMousePosition.X,
            mouse.dwMousePosition.Y,
        });
        handle_flag = true;
    }

    // 检测滚轮
    if (mouse.dwEventFlags & MOUSE_WHEELED != 0) {
        const delta = @as(i32, @bitCast(mouse.dwButtonState)) >> 16;
        const direction = if (delta > 0) "up" else "down";
        logger.logDebugFmt("mouse wheel {s}: ({}, {})", .{
            direction,
            mouse.dwMousePosition.X,
            mouse.dwMousePosition.Y,
        });
        handle_flag = true;
    }
    if (!handle_flag) {
        logger.logWarningFmt("Unhandled mouse event - pos:({},{}), buttons:{X:0>8}, flags:{X:0>8}", .{ mouse.dwMousePosition.X, mouse.dwMousePosition.Y, mouse.dwButtonState, mouse.dwEventFlags });
    }
}

var parser = Parser{};
inline fn handleKeyEvent(record: INPUT_RECORD) void {
    parser.processEvent(record.Event.KeyEvent);
    // const key = record.Event.KeyEvent;
    // if (key.bKeyDown != 0) {
    //     logger.logDebugFmt("key down: {X:0>4}", .{key.wVirtualKeyCode});
    // }
}
