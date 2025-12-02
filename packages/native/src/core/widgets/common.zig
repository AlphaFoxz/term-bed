const std = @import("std");
const typedef = @import("../typedef.zig");
const TuiScale = typedef.TuiScale;

var id_generator = std.atomic.Value(u64).init(0);

pub fn genId() u64 {
    return id_generator.fetchAdd(1, .monotonic);
}

pub const WidgetInfo = struct {
    x: TuiScale,
    y: TuiScale,
    width: TuiScale,
    height: TuiScale,
    visible: bool,
    z_index: i32,
};

const testing = std.testing;
const builtin = @import("builtin");

fn expectFunction(t: anytype) void {
    if (!builtin.is_test) {
        @compileError("expectFunction can only be called in test mode");
    }
    const Type = std.builtin.Type;
    switch (@typeInfo(@TypeOf(t))) {
        Type.@"fn" => {},
        else => return error.NotWidget,
    }
}

pub fn expectWidget(t: anytype) !void {
    expectFunction(t.getCommonInfo);
    expectFunction(t.updateInfo);
    expectFunction(t.init);
    expectFunction(t.deinit);
}
