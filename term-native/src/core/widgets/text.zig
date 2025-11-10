const std = @import("std");
const TuiRect = @import("./structures.zig").TuiRect;
const String = @import("../string.zig").String;
const alloc = @import("../alloc.zig");

pub const Text = struct {
    rect: TuiRect,
    text: *String,

    pub fn destroy(self: *Text) void {
        alloc.allocator().destroy(self);
        self.text.deinit();
    }
};

pub fn createText(
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    text: *String,
) *Text {
    const text_prt = alloc.allocator().create(Text) catch {
        std.log.err("Out of memory", .{});
        std.process.exit(1);
    };
    text_prt.* = Text{
        .rect = TuiRect{ .x = x, .y = y, .rows = height, .cols = width },
        .text = text,
    };
    return text_prt;
}
