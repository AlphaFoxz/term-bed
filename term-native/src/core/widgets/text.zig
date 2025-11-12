const std = @import("std");
const wdt_common = @import("./common.zig");
const String = @import("../string.zig").String;
const glo_alloc = @import("../glo_alloc.zig");
const err = @import("../error.zig");

pub const Text = struct {
    alloc: std.mem.Allocator,
    id: u64,
    rect: wdt_common.TuiRect,
    visible: bool,
    text: *String,

    pub fn init(
        alloc: std.mem.Allocator,
        rect: wdt_common.TuiRect,
        visible: bool,
        text: *String,
    ) *Text {
        const text_prt = alloc.create(Text) catch {
            std.log.err("Out of memory", .{});
            std.process.exit(1);
        };
        text_prt.* = Text{
            .alloc = alloc,
            .id = wdt_common.genId(),
            .rect = rect,
            .visible = visible,
            .text = text,
        };
        return text_prt;
    }

    pub fn deinit(self: *Text) void {
        defer self.text.deinit();
        self.alloc.allocator().destroy(self);
    }

    pub fn getRect(self: *Text) *wdt_common.TuiRect {
        return &self.rect;
    }
    pub fn setPos(self: *Text, x: u16, y: u16) void {
        self.rect.x = x;
        self.rect.y = y;
    }
    pub fn setWidth(self: *Text, width: u16) void {
        self.rect.cols = width;
    }
    pub fn setHeight(self: *Text, height: u16) void {
        self.rect.rows = height;
    }
};

pub fn createText(
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    visible: bool,
    text: *String,
) *Text {
    const alloc = glo_alloc.allocator();
    const text_ptr = Text.init(
        alloc,
        wdt_common.TuiRect{
            .x = x,
            .y = y,
            .rows = height,
            .cols = width,
        },
        visible,
        text,
    );

    return text_ptr;
}
