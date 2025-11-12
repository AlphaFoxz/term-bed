pub const common = @import("./widgets/common.zig");
pub const text = @import("./widgets/text.zig");
pub const scene = @import("./widgets/scene.zig");

pub fn destroyWidget(widget: *common.Widget) void {
    widget.deinit();
}

const testing = @import("std").testing;

test "expect which is Widget type" {
    try common.expectWidget(text.Text);
}
