const std = @import("std");
const glo_alloc = @import("../core/glo_alloc.zig");
const err = @import("../core/error.zig");
const TuiScale = @import("../core/typedef.zig").TuiScale;

pub const CellType = enum {
    Ascii,
    Wide,
    Hidden,
};

pub const TuiCell = extern struct {
    char: u32,
    fg: u32,
    bg: u32,
    style: u32,
};

var frame_size: TuiScale = 0;
var current_frame: []TuiCell = &[_]TuiCell{};
var next_frame: []TuiCell = &[_]TuiCell{};
var dirty_frame: []bool = &[_]bool{};

fn init(allocator: std.mem.Allocator, size: TuiScale) void {
    current_frame = allocator.alloc(TuiCell, size) catch {
        err.outOfMemory();
    };
    next_frame = allocator.alloc(TuiCell, size) catch {
        err.outOfMemory();
    };
    dirty_frame = allocator.alloc(bool, size) catch {
        err.outOfMemory();
    };
    frame_size = size;
    resetFrame(current_frame);
    resetFrame(next_frame);
    resetFrame(dirty_frame);
}

pub fn init_safety(width: TuiScale, height: TuiScale) void {
    const alloc = glo_alloc.allocator();
    if (current_frame.len > 0) {
        glo_alloc.allocator().free(current_frame);
    }
    if (next_frame.len > 0) {
        glo_alloc.allocator().free(next_frame);
    }
    if (dirty_frame.len > 0) {
        glo_alloc.allocator().free(dirty_frame);
    }
    const size: TuiScale = width * height;
    init(alloc, size);
}

inline fn resetDirtyFrame(frame: []bool) void {
    for (0..frame.len) |idx| {
        frame[idx] = false;
    }
}
inline fn resetFrame(frame: *[]TuiCell) void {
    const size = current_frame.len;
    for (0..size) |idx| {
        frame[idx] = TuiCell{
            .char = 0,
            .fg = 0,
            .bg = 0,
            .style = 0,
        };
    }
}

pub fn deinit() void {
    glo_alloc.allocator().free(current_frame);
    glo_alloc.allocator().free(next_frame);
    glo_alloc.allocator().free(dirty_frame);
    frame_size = 0;
}
