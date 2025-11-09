const std = @import("std");

pub const TuiContext = struct {};

pub const TuiSize = struct {
    cols: u16,
    rows: u16,
};

pub fn createTuiContext() TuiContext {
    return TuiContext{};
}
