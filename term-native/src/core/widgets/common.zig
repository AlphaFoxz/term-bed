const std = @import("std");
const TuiScale = u16;

pub const TuiRect = struct {
    x: TuiScale,
    y: TuiScale,
    rows: TuiScale,
    cols: TuiScale,
};

var id_generator = std.atomic.Value(u64).init(0);

pub fn genId() u64 {
    return id_generator.fetchAdd(1, .monotonic);
}
