const alloc = @import("./alloc.zig");

pub const text = @import("./widgets/text.zig");

pub const Widget = struct {};

pub fn destroyWidget(widget: *Widget) void {
    alloc.allocator().destroy(widget);
}
