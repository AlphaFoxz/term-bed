const std = @import("std");
const logger = @import("../core/logger.zig");
const windows = std.os.windows;
const mode = @import("./windows_mode.zig");
const event_bus = @import("../core/event_bus.zig");
const mapper = @import("./mapper.zig");

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

const RIGHT_ALT_PRESSED = 0x0001;
const LEFT_ALT_PRESSED = 0x0002;
const RIGHT_CTRL_PRESSED = 0x0004;
const LEFT_CTRL_PRESSED = 0x0008;
const SHIFT_PRESSED = 0x0010;

// 定义简单的状态机状态
const InputState = enum {
    Normal,
    EscReceived, // 收到了 \x1b
    CsiReceived, // 收到了 [
    // 实际的 parser 可能会更复杂，这里简化演示
};

// See https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent
const keyboard_event_fmt =
    \\{{"key":{s},"shiftKey":{},"altKey":{},"ctrlKey":{},"metaKey":{},"repeat":{},"charCode":{d}}}
;
const keyboard_event_fmt2 =
    \\{{"key":"{u}","shiftKey":{},"altKey":{},"ctrlKey":{},"metaKey":{},"repeat":{},"charCode":{d}}}
;
const mouse_event_fmt =
    \\{{"button":{s},"buttons":{s},"x":{d},"y":{d},"shiftKey":{},"altKey":{},"ctrlKey":{},"metaKey":{}}}
;
var event_buf: [256]u8 = undefined;

inline fn keyboardEventJson(comptime is_char: bool, attrs: struct { key: []const u8, is_shift: bool, is_alt: bool, is_ctrl: bool, is_meta: bool, is_repeat: bool, char_code: u16 }) []const u8 {
    const fmt = if (is_char) keyboard_event_fmt2 else keyboard_event_fmt;
    return std.fmt.bufPrint(
        &event_buf,
        fmt,
        .{
            if (is_char) attrs.char_code else attrs.key,
            attrs.is_shift,
            attrs.is_alt,
            attrs.is_ctrl,
            attrs.is_meta,
            attrs.is_repeat,
            attrs.char_code,
        },
    ) catch unreachable;
}
inline fn mouseEventJson(attrs: struct { button: []const u8, buttons: []const u8, x: i32, y: i32, is_shift: bool, is_alt: bool, is_ctrl: bool, is_meta: bool }) []const u8 {
    return std.fmt.bufPrint(
        &event_buf,
        mouse_event_fmt,
        .{
            attrs.button,
            attrs.buttons,
            attrs.x,
            attrs.y,
            attrs.is_shift,
            attrs.is_alt,
            attrs.is_ctrl,
            attrs.is_meta,
        },
    ) catch unreachable;
}
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
    pub fn bak(self: *Parser, record: KEY_EVENT_RECORD) void {
        // 1. 过滤掉按键释放事件
        if (record.bKeyDown == 0) return;

        const char_code = record.uChar.UnicodeChar;
        const vk = record.wVirtualKeyCode;
        const ctrl_state = record.dwControlKeyState; // 如果你需要判断 Ctrl+F1 之类的

        // ---------------------------------------------------------
        // 优先处理：功能键 (Function Keys) & 导航键
        // 这些键通常 uChar == 0，必须通过 VirtualKeyCode 判断
        // ---------------------------------------------------------
        // VK_F1 (0x70) 到 VK_F24 (0x87)
        if (vk >= VK_F1 and vk <= VK_F24) {
            const f_key_num = vk - VK_F1 + 1;
            logger.logDebugFmt("检测到功能键: F{d}", .{f_key_num});

            // 在这里调用你的处理逻辑，例如：
            // self.handleFunctionKey(f_key_num);
            self.reset();
            return;
        }

        // 其他常见的非字符键处理
        switch (vk) {
            windows.VK_LEFT, windows.VK_RIGHT, windows.VK_UP, windows.VK_DOWN => {
                // 处理方向键
                logger.logDebug("检测到方向键");
                self.reset();
                return;
            },
            windows.VK_DELETE => {
                // 处理删除
                self.reset();
                return;
            },
            // ... 处理 Home, End, PageUp 等
            else => {},
        }

        // ---------------------------------------------------------
        // 情况 A: 汉字 / Unicode 字符
        // ---------------------------------------------------------
        if (char_code > 0xFF) {
            logger.logDebugFmt("汉字/Unicode输入: {u}", .{char_code});
            self.reset();
            return;
        }

        const ascii: u8 = @intCast(char_code);

        // ---------------------------------------------------------
        // 情况 B: 状态机 (处理 ESC 序列，如鼠标或 Alt+Key)
        // ---------------------------------------------------------
        // 注意：如果 uChar 是 0 (且上面没处理完)，这里 ascii 也会是 0
        // 0 不是 0x1B，所以不会进入 EscReceived

        switch (self.state) {
            .Normal => {
                if (ascii == 0x1B) { // ESC 键
                    self.state = .EscReceived;
                    self.buf_idx = 0;
                    self.buffer[self.buf_idx] = ascii;
                    self.buf_idx += 1;
                } else if (ascii != 0) {
                    // 只有当 ascii != 0 时才处理为普通字符
                    // 避免把未处理的特殊键(uChar=0)当成 NULL 字符处理
                    self.handleNormalKey(record);
                }
            },
            // ... (EscReceived 和 CsiReceived 保持不变) ...
            .EscReceived => {
                if (ascii == '[') {
                    self.state = .CsiReceived;
                    self.buffer[self.buf_idx] = ascii;
                    self.buf_idx += 1;
                } else {
                    // ESC + 字符 (例如 Alt+A 可能会产生 ESC 然后 A)
                    logger.logDebug("按键: ESC");
                    self.reset();
                    // 重新分发当前字符
                    self.processEvent(record);
                }
            },
            .CsiReceived => {
                self.buffer[self.buf_idx] = ascii;
                self.buf_idx += 1;
                if ((ascii >= 'A' and ascii <= 'Z') or (ascii >= 'a' and ascii <= 'z') or ascii == '~') {
                    self.parseSequence();
                    self.reset();
                }
            },
        }
    }

    fn handleNormalKey(_: *Parser, record: KEY_EVENT_RECORD) void {
        const unicode_char = record.uChar.UnicodeChar;
        const virtual_code = record.wVirtualKeyCode;
        const state = record.dwControlKeyState;
        const is_ctrl = (state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) != 0;
        const is_alt = (state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
        const is_shift = (state & SHIFT_PRESSED) != 0;
        const is_repeat = record.wRepeatCount > 1;
        var slice: ?[]const u8 = null;

        if (unicode_char == 0) {
            logger.logDebugFmt("特殊键 (VirtualKey: {})", .{virtual_code});
            // 情况 1: 特殊键 (F1, Home, Arrow, etc.)
            // char 字段设为 null，只传 code
            logger.logDebugFmt("特殊键: {}", .{virtual_code});
            // To learn more about `virtual_code` and `key_name`,
            // see https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values

            const key = mapper.mapWindowsVirtualKeyCode(virtual_code);
            slice = keyboardEventJson(false, .{
                .key = "null",
                .is_shift = is_shift,
                .is_alt = is_alt,
                .is_ctrl = is_ctrl,
                .is_meta = key == mapper.VirtualKeyCodes.Meta,
                .is_repeat = is_repeat,
                .char_code = @intFromEnum(key),
            });
        } else if (unicode_char < 32) {
            logger.logDebugFmt("控制字符 (Ctrl+Key): {}", .{unicode_char});
            // slice = keyboardEventJson(
            //     false,
            //     .{
            //         .key = "",
            //         .is_shift = is_shift,
            //         .is_alt = is_alt,
            //         .is_ctrl = is_ctrl,
            //         .is_meta = false,
            //         .is_repeat = is_repeat,
            //         .char_code = unicode_char,
            //     },
            // );
        } else {
            logger.logDebugFmt("普通字符: {u}", .{unicode_char});
            slice = keyboardEventJson(true, .{
                .key = "",
                .is_shift = is_shift,
                .is_alt = is_alt,
                .is_ctrl = is_ctrl,
                .is_meta = false,
                .is_repeat = is_repeat,
                .char_code = unicode_char,
            });
        }

        if (slice) |s| {
            _ = event_bus.event_bus_emit_bytes(
                @intFromEnum(event_bus.EventType.KeyEvent),
                s,
            );
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

            var button: ?[]const u8 = null;
            var buttons: ?[]const u8 = null;

            switch (pb) {
                0 => {
                    logger.logDebugFmt("鼠标左键{s}，x: {}, y: {}", .{
                        if (is_release) "释放" else "按下",
                        px,
                        py,
                    });
                    button = "0";
                },
                1 => {
                    logger.logDebugFmt("鼠标中键{s}，x: {}, y: {}", .{
                        if (is_release) "释放" else "按下",
                        px,
                        py,
                    });
                    button = "1";
                },
                2 => {
                    logger.logDebugFmt("鼠标右键{s}，x: {}, y: {}", .{
                        if (is_release) "释放" else "按下",
                        px,
                        py,
                    });
                    button = "2";
                },
                3 => {
                    logger.logDebugFmt("鼠标移动，x: {}, y: {}, 是否拖动: {}", .{ px, py, is_drag });
                    if (is_drag) {
                        buttons = "1";
                    } else {
                        buttons = "0";
                    }
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
            if (button) |b| {
                _ = event_bus.event_bus_emit_bytes(
                    @intFromEnum(event_bus.EventType.MouseEvent),
                    mouseEventJson(
                        .{
                            .button = b,
                            .buttons = "null",
                            .x = px,
                            .y = py,
                            .is_shift = is_shift,
                            .is_alt = is_alt,
                            .is_ctrl = is_ctrl,
                            .is_meta = false,
                        },
                    ),
                );
            } else if (buttons) |b| {
                _ = event_bus.event_bus_emit_bytes(
                    @intFromEnum(event_bus.EventType.MouseEvent),
                    mouseEventJson(
                        .{
                            .button = "null",
                            .buttons = b,
                            .x = px,
                            .y = py,
                            .is_shift = is_shift,
                            .is_alt = is_alt,
                            .is_ctrl = is_ctrl,
                            .is_meta = false,
                        },
                    ),
                );
            }
            return;
        }
        // var slice: ?[]u8 = null;
        if (std.mem.eql(u8, seq, "\x1b[A")) {
            logger.logDebugFmt("方向键: UP", .{});
            // slice = std.fmt.bufPrint(
            //     &event_buf,
            //     keyboard_event_fmt,
            //     .{seq},
            // ) catch unreachable;
        } else if (std.mem.eql(u8, seq, "\x1b[B")) {
            logger.logDebugFmt("方向键: DOWN", .{});
        } else if (std.mem.eql(u8, seq, "\x1b[C")) {
            logger.logDebugFmt("方向键: RIGHT", .{});
        } else if (std.mem.eql(u8, seq, "\x1b[D")) {
            logger.logDebugFmt("方向键: LEFT", .{});
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
        if (logger.current_log_level == logger.LOG_LEVEL_DEBUG) {
            logger.flush();
        }
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
