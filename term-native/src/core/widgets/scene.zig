const std = @import("std");
const wdt_common = @import("./common.zig");
const err = @import("../error.zig");
const glo_alloc = @import("../glo_alloc.zig");

pub const Scene = struct {
    alloc: std.mem.Allocator,
    id: u64,
    rect: wdt_common.TuiRect,
    visible: bool,

    pub fn init(alloc: std.mem.Allocator, rect: wdt_common.TuiRect, visible: bool) *Scene {
        const ptr = alloc.create(Scene) catch {
            err.outOfMemory();
        };
        ptr.* = Scene{
            .alloc = alloc,
            .id = wdt_common.genId(),
            .rect = rect,
            .visible = visible,
        };
        return ptr;
    }
    pub fn deinit(self: *Scene) void {
        defer self.alloc.destroy(self);
    }

    pub fn getRect(self: *Scene) *wdt_common.TuiRect {
        return &self.rect;
    }
    pub fn setPos(self: *Scene, x: u16, y: u16) void {
        self.rect.x = x;
        self.rect.y = y;
    }
    pub fn setWidth(self: *Scene, width: u16) void {
        self.rect.cols = width;
    }
    pub fn setHeight(self: *Scene, height: u16) void {
        self.rect.rows = height;
    }
};

pub fn createScene(visible: bool) *Scene {
    const alloc = glo_alloc.allocator();
    return Scene.init(
        alloc,
        wdt_common.TuiRect{
            .x = 0,
            .y = 0,
            .rows = 0,
            .cols = 0,
        },
        visible,
    );
}

pub fn destroyScene(scene: *Scene) void {
    scene.deinit();
}
