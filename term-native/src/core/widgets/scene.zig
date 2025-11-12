const std = @import("std");
const wdt_common = @import("./common.zig");
const err = @import("../error.zig");
const glo_alloc = @import("../glo_alloc.zig");
const typedef = @import("../typedef.zig");
const TuiScale = typedef.TuiScale;

pub const s = Scene;

pub const Scene = struct {
    alloc: std.mem.Allocator,
    id: u64,
    rect: wdt_common.WidgetInfo,
    visible: bool,

    pub fn init(visible: bool) *Scene {
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
        };
        return ptr;
    }

    pub fn deinit(self: *Scene) void {
        defer self.alloc.destroy(self);
    }
};
