const std = @import("std");

const alloc = std.heap.c_allocator;

pub fn init() void {}

pub fn allocator() std.mem.Allocator {
    return alloc;
}

pub fn deinit() void {}
