const std = @import("std");
const wdt_common = @import("./common.zig");
const err = @import("../error.zig");
const glo_alloc = @import("../glo_alloc.zig");
const typedef = @import("../typedef.zig");
const TuiScale = typedef.TuiScale;
const Rgba = @import("../../ansi_util/style.zig").Rgba;

pub const Scene = struct {
    alloc: std.mem.Allocator,
    id: u64,
    rect: wdt_common.WidgetInfo,
    visible: bool,
    background_color: Rgba,

    pub fn init(visible: bool, background_color: Rgba) *Scene {
        const alloc = glo_alloc.allocator();
        const ptr = alloc.create(Scene) catch {
            err.outOfMemory();
        };
        ptr.* = Scene{
            .alloc = alloc,
            .id = wdt_common.genId(),
            .rect = wdt_common.WidgetInfo{
                .x = 0,
                .y = 0,
                .width = 0,
                .height = 0,
                .visible = visible,
                .z_index = 0,
            },
            .visible = visible,
            .background_color = background_color,
        };
        return ptr;
    }

    pub fn deinit(self: *Scene) void {
        defer self.alloc.destroy(self);
    }
};
