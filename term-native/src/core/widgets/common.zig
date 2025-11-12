const std = @import("std");
const TuiScale = u16;

pub const TuiRect = struct {
    x: TuiScale,
    y: TuiScale,
    rows: TuiScale,
    cols: TuiScale,
};

pub const WidgetVTable = struct {
    getRect: *const fn (self: *anyopaque) *TuiRect,
    setPos: *const fn (self: *anyopaque, x: TuiScale, y: TuiScale) void,
    setWidth: *const fn (self: *anyopaque, width: TuiScale) void,
    setHeight: *const fn (self: *anyopaque, height: TuiScale) void,
    deinit: *const fn (self: *anyopaque) void,
};

pub const Widget = struct {
    ptr: *anyopaque,
    vtable: *const WidgetVTable,

    pub fn getRect(self: *Widget) *TuiRect {
        return self.vtable.getRect(self.ptr);
    }
    pub fn setPos(self: *Widget, x: TuiScale, y: TuiScale) void {
        self.vtable.setPos(self.ptr, x, y);
    }
    pub fn setWidth(self: *Widget, width: TuiScale) void {
        self.vtable.setWidth(self.ptr, width);
    }
    pub fn setHeight(self: *Widget, height: TuiScale) void {
        self.vtable.setHeight(self.ptr, height);
    }
    pub fn deinit(self: *Widget) void {
        self.vtable.deinit(self.ptr);
    }
};

var id_generator = std.atomic.Value(u64).init(0);

pub fn genId() u64 {
    return id_generator.fetchAdd(1, .monotonic);
}

const testing = std.testing;

fn expectFunction(t: anytype) void {
    const Type = std.builtin.Type;
    switch (@typeInfo(@TypeOf(t))) {
        Type.@"fn" => {},
        else => return error.NotWidget,
    }
}

pub fn expectWidget(t: anytype) !void {
    expectFunction(t.getRect);
    expectFunction(t.setPos);
    expectFunction(t.setWidth);
    expectFunction(t.setHeight);
}
