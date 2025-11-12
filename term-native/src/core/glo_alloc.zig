const std = @import("std");
const builtin = @import("builtin");

var g_debug_alloc_inst = std.heap.DebugAllocator(.{}){};
var debug_alloc: std.mem.Allocator = undefined;
var debug_mode = false;

pub fn allocator() std.mem.Allocator {
    if (debug_mode) {
        return debug_alloc;
    }
    return std.heap.c_allocator;
}

pub fn debugMode() void {
    if (!builtin.is_test) {
        @compileError("debugMode can only be called in test mode");
    }
    debug_alloc = g_debug_alloc_inst.allocator();
    debug_mode = true;
}
