const std = @import("std");
const wdt_common = @import("./common.zig");
const String = @import("../string.zig").String;
const glo_alloc = @import("../glo_alloc.zig");
const err = @import("../error.zig");

pub const Text = struct {
    alloc: std.mem.Allocator,
    id: u64,
    rect: wdt_common.WidgetInfo,
    visible: bool,
    text: *String,

    pub fn init(
        x: u16,
        y: u16,
        width: u16,
        height: u16,
        visible: bool,
        text: *String,
    ) *Text {
        const alloc = glo_alloc.allocator();
        const text_prt = alloc.create(Text) catch {
            std.log.err("Out of memory", .{});
            std.process.exit(1);
        };
        text_prt.* = Text{
            .alloc = alloc,
            .id = wdt_common.genId(),
            .rect = wdt_common.WidgetInfo{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
                .visible = visible,
                .z_index = 0,
            },
            .visible = visible,
            .text = text,
        };
        return text_prt;
    }

    pub fn deinit(self: *Text) void {
        defer self.alloc.destroy(self);
        self.text.deinit();
    }
};
