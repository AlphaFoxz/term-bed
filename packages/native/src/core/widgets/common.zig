const std = @import("std");
const typedef = @import("../typedef.zig");
const TuiScale = typedef.TuiScale;
const glo_alloc = @import("../glo_alloc.zig");
const err = @import("../error.zig");

var id_generator = std.atomic.Value(u64).init(1);

pub fn genId() u64 {
    return id_generator.fetchAdd(1, .monotonic);
}

const Point = packed struct {
    x: TuiScale,
    y: TuiScale,
};

const Rect = packed struct {
    width: TuiScale,
    height: TuiScale,
};

pub const RectWidgetInfo = extern struct {
    id: u64,
    position: Point,
    rect: Rect,
    z_index: i32,
    visible: u8,

    pub fn init(x: u16, y: u16, width: u16, height: u16, z_index: i32, visible: u8) *RectWidgetInfo {
        const info = glo_alloc.allocator().create(RectWidgetInfo) catch {
            err.outOfMemory();
        };
        info.* = RectWidgetInfo{
            .id = genId(),
            .position = Point{
                .x = x,
                .y = y,
            },
            .rect = Rect{
                .width = width,
                .height = height,
            },
            .z_index = z_index,
            .visible = visible,
        };
        return info;
    }

    pub fn deinit(self: *const RectWidgetInfo) void {
        glo_alloc.allocator().destroy(self);
    }
};
