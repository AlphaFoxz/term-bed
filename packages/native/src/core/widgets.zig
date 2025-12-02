pub const common = @import("./widgets/common.zig");
pub const text = @import("./widgets/text.zig");
pub const scene = @import("./widgets/scene.zig");
const std = @import("std");
const err = @import("./error.zig");
const typedef = @import("./typedef.zig");
const TuiScale = typedef.TuiScale;
const glo_alloc = @import("./glo_alloc.zig");

pub fn destroyWidget(widget: *common.Widget) void {
    widget.deinit();
}

pub const Widget = union(enum) {
    text: *text.Text,
    scene: *scene.Scene,

    pub fn updateInfo(self: Widget, x: ?TuiScale, y: ?TuiScale, width: ?TuiScale, height: ?TuiScale, visible: ?bool, z_index: ?i32) void {
        switch (self) {
            inline else => |s| updateWidgetInfo(s, x, y, width, height, visible, z_index),
        }
    }

    pub fn getInfo(self: Widget) []const u8 {
        switch (self) {
            inline else => |s| return widgetInfoToJsonStr(s.rect),
        }
    }

    pub fn getCommonInfo(self: Widget) []const u8 {
        switch (self) {
            inline else => |s| return s.getCommonInfo(),
        }
    }

    pub fn deinit(self: Widget) void {
        switch (self) {
            inline else => |s| s.deinit(),
        }
    }
};

pub fn updateWidgetInfo(self: *scene.Scene, x: ?TuiScale, y: ?TuiScale, width: ?TuiScale, height: ?TuiScale, visible: ?bool, z_index: ?i32) void {
    self.rect.x = x orelse self.rect.x;
    self.rect.y = y orelse self.rect.y;
    self.rect.width = width orelse self.rect.width;
    self.rect.height = height orelse self.rect.height;
    self.rect.visible = visible orelse self.rect.visible;
    self.rect.z_index = z_index orelse self.rect.z_index;
}

pub fn widgetInfoToJsonStr(self: common.WidgetInfo) []const u8 {
    const buffer = std.ArrayList(u8).initCapacity(glo_alloc.allocator(), 88) catch {
        err.outOfMemory();
    };
    var stringfier = std.json.Stringify{
        .writer = buffer,
        .options = .{
            .whitespace = .minified,
            .emit_null_optional_fields = false,
        },
    };
    stringfier.write(self.rect);
    return buffer.items;
}

const testing = @import("std").testing;

test "expect which is Widget type" {
    try common.expectWidget(text.Text);
    try common.expectWidget(scene.Scene);
}
