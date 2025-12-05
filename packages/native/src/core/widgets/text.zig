const std = @import("std");
const wdt_common = @import("./common.zig");
const String = @import("../string.zig").String;
const glo_alloc = @import("../glo_alloc.zig");
const err = @import("../error.zig");

pub const Text = struct {
    base_info: *const wdt_common.RectWidgetInfo,
    text: *String,
};
