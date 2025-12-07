pub const common = @import("./widgets/common.zig");
pub const text = @import("./widgets/text.zig");
const std = @import("std");
const err = @import("./error.zig");
const typedef = @import("./typedef.zig");
const TuiScale = typedef.TuiScale;
const glo_alloc = @import("./glo_alloc.zig");
const String = @import("./string.zig").String;

pub const Widget = union(enum) {
    Text: text.Text,
};

pub fn initTextWidget(base_info: *common.RectWidgetInfo, str: *String) *Widget {
    const alloc = glo_alloc.allocator();
    const widget = alloc.create(Widget) catch {
        err.outOfMemory();
    };
    widget.* = Widget{ .Text = text.Text{
        .base_info = base_info,
        .text = str,
    } };
    return widget;
}
pub fn deinitWidget(self: *Widget) void {
    const alloc = glo_alloc.allocator();
    defer alloc.destroy(self);
    switch (self.*) {
        .Text => |v| {
            v.base_info.deinit();
            v.text.deinit();
        },
    }
}
