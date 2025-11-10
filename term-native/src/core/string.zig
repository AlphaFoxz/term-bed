const std = @import("std");
const err = @import("../error.zig");
const logger = @import("./logger.zig");
// const gpa = std.heap.GeneralPurposeAllocator(.{}){};
const str_alloc = std.heap.c_allocator;

pub const String = struct {
    ptr: *String,
    buffer: std.ArrayList(u8),

    pub fn init() *String {
        const ptr = try str_alloc.create(String);
        ptr.* = String{ .ptr = ptr, .buffer = try std.ArrayList(u8).init(str_alloc) };
        return ptr;
    }

    pub fn from(slice: []u8) *String {
        const ptr = str_alloc.create(String) catch {
            err.outOfMemory();
        };
        const buffer = std.ArrayList(u8).init(str_alloc) catch {
            err.outOfMemory();
        };
        ptr.* = String{ .ptr = ptr, .buffer = buffer };
        ptr.*.append(slice);
        return ptr;
    }

    pub fn fromCString(slice: [*:0]const u8) *String {
        const ptr = str_alloc.create(String) catch {
            err.outOfMemory();
            unreachable;
        };
        // errdefer str_alloc.destroy(ptr);

        const s = std.mem.span(slice);

        var buffer = std.ArrayList(u8).initCapacity(str_alloc, s.len) catch {
            err.outOfMemory();
            unreachable;
        };
        buffer.appendSlice(str_alloc, s) catch {
            err.outOfMemory();
            unreachable;
        };
        ptr.* = String{
            .ptr = ptr,
            .buffer = buffer,
        };
        return ptr;
    }

    pub fn append(self: *String, slice: []u8) !void {
        try self.buffer.appendSlice(slice);
    }

    pub fn set(self: *String, slice: []u8) void {
        self.buffer.clearRetainingCapacity();
        self.buffer.appendSlice(slice) catch unreachable;
    }

    pub fn clear(self: *String) void {
        self.buffer.clearRetainingCapacity();
    }

    pub fn deinit(self: *String) void {
        self.buffer.deinit();
        str_alloc.destroy(self.ptr);
    }
};
