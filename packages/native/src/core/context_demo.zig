const std = @import("std");
const arena = @import("./arena.zig");

// 不透明句柄：仅声明类型，不暴露内部结构
pub const TuiContext = opaque {};

// 色彩与属性
pub const TuiCell = extern struct {
    glyph_ptr: [*]const u8, // UTF-8 字节序列指针
    glyph_len: usize, // UTF-8 长度（字节）
    fg_rgb: u32, // 0xRRGGBB；0xFF000000 表示默认
    bg_rgb: u32, // 0xRRGGBB；0xFF000000 表示默认
    attrs: u32, // bitflags: 1=bold,2=italic,4=underline,8=inverse...
};

pub const TuiSpan = extern struct {
    row: u16,
    col: u16,
    len: u16, // cells_ptr 中的有效 cell 数
    cells_ptr: [*]const TuiCell, // 连续 cell 段（一个水平区间）
};

pub const TuiSize = extern struct {
    cols: u16,
    rows: u16,
};

// 生命周期与状态函数
pub extern fn createContext() *TuiContext;
pub extern fn tui_shutdown(ctx: *TuiContext) void;

pub extern fn tui_enter_alt_screen(ctx: *TuiContext) c_int;
pub extern fn tui_leave_alt_screen(ctx: *TuiContext) c_int;

pub extern fn tui_set_raw_mode(ctx: *TuiContext, enable: c_int) c_int;
pub extern fn tui_get_size(ctx: *TuiContext) TuiSize;

pub extern fn tui_begin_frame(ctx: *TuiContext) void;
pub extern fn tui_draw_spans(ctx: *TuiContext, spans: [*]const TuiSpan, count: usize) void;
pub extern fn tui_end_frame(ctx: *TuiContext) c_int;

// 输入事件类型
pub const TuiEventKind = enum(c_int) {
    Key,
    Mouse,
    Paste,
    Resize,
};

// 各事件数据结构
pub const TuiKey = extern struct {
    code: u32,
    mods: u8,
};

pub const TuiMouse = extern struct {
    x: u16,
    y: u16,
    kind: u8,
    mods: u8,
    wheel: i16,
};

pub const TuiPaste = extern struct {
    ptr: [*]const u8,
    len: usize,
};

pub const TuiResize = extern struct {
    cols: u16,
    rows: u16,
};

// 事件总结构
pub const TuiEvent = extern struct {
    kind: TuiEventKind,
    data: extern union {
        key: TuiKey,
        mouse: TuiMouse,
        paste: TuiPaste,
        resize: TuiResize,
    },
};

pub extern fn tui_poll_events(ctx: *TuiContext, out: [*]TuiEvent, capacity: usize) usize;
