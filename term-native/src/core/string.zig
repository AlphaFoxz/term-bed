const std = @import("std");
const err = @import("../error.zig");
const logger = @import("./logger.zig");
// const gpa = std.heap.GeneralPurposeAllocator(.{}){};
const str_alloc = std.heap.c_allocator;

pub const Utf8Iterator = struct {
    bytes: []const u8,
    index: usize,

    pub fn next(self: *Utf8Iterator) ?[]const u8 {
        if (self.index >= self.bytes.len) return null;

        const start = self.index;
        const len = std.unicode.utf8ByteSequenceLength(self.bytes[start]) catch 1;

        if (start + len > self.bytes.len) {
            self.index = self.bytes.len;
            return null;
        }

        self.index += len;
        return self.bytes[start..self.index];
    }

    pub fn preview(self: *Utf8Iterator) ?[]const u8 {
        if (self.index >= self.bytes.len) return null;

        const start = self.index;
        const len = std.unicode.utf8ByteSequenceLength(self.bytes[start]) catch 1;

        if (start + len > self.bytes.len) {
            self.index = self.bytes.len;
            return null;
        }
        return self.bytes[start .. self.index + len];
    }

    pub fn reset(self: *Utf8Iterator) void {
        self.index = 0;
    }
};

pub const String = struct {
    buffer: std.ArrayList(u8),

    pub fn init() *String {
        const ptr = str_alloc.create(String) catch {
            err.outOfMemory();
        };
        ptr.* = String{
            .buffer = std.ArrayList(u8).initCapacity(str_alloc) catch {
                err.outOfMemory();
            },
        };
        return ptr;
    }

    pub fn initFromSclice(slice: []const u8) *String {
        const ptr = str_alloc.create(String) catch {
            err.outOfMemory();
        };
        const buffer = std.ArrayList(u8).initCapacity(str_alloc, slice.len) catch {
            err.outOfMemory();
        };
        ptr.* = String{ .buffer = buffer };
        ptr.*.append(slice);
        return ptr;
    }

    pub fn initFromCSclice(slice: [*:0]const u8) *String {
        const ptr = str_alloc.create(String) catch {
            err.outOfMemory();
        };
        // errdefer str_alloc.destroy(ptr);

        const s = std.mem.span(slice);

        var buffer = std.ArrayList(u8).initCapacity(str_alloc, s.len) catch {
            err.outOfMemory();
        };
        buffer.appendSlice(str_alloc, s) catch {
            err.outOfMemory();
        };
        ptr.* = String{ .buffer = buffer };
        return ptr;
    }

    pub fn append(self: *String, slice: []const u8) void {
        self.buffer.appendSlice(str_alloc, slice) catch {
            err.outOfMemory();
        };
    }

    pub fn set(self: *String, slice: []const u8) void {
        self.buffer.clearRetainingCapacity();
        self.buffer.appendSlice(str_alloc, slice) catch {
            err.outOfMemory();
        };
    }

    pub fn clear(self: *String) void {
        self.buffer.clearRetainingCapacity();
    }

    pub fn iter(self: *String) Utf8Iterator {
        return Utf8Iterator{
            .bytes = self.buffer.items,
            .index = 0,
        };
    }
    pub fn toSlice(self: *String) []u8 {
        return self.buffer.items;
    }

    pub fn deinit(self: *String) void {
        self.buffer.deinit(str_alloc);
        str_alloc.destroy(self);
    }
};

pub fn getDisplayWidthStd(s: []const u8) usize {
    var width: usize = 0;
    const view = std.unicode.Utf8View.init(s) catch return s.len;
    var iter = view.iterator();
    while (iter.nextCodepoint()) |codepoint| {
        width += unicodeWidth(codepoint);
    }
    return width;
}

// Unicode 字符宽度判断
fn unicodeWidth(codepoint: u21) usize {
    // 简化版本，实际应该使用 East Asian Width 数据
    if (codepoint < 0x80) return 1; // ASCII
    if (codepoint >= 0x4E00 and codepoint <= 0x9FFF) return 2; // CJK统一汉字
    if (codepoint >= 0x3000 and codepoint <= 0x303F) return 2; // CJK符号
    if (codepoint >= 0xFF00 and codepoint <= 0xFFEF) return 2; // 全角字符
    if (codepoint >= 0xAC00 and codepoint <= 0xD7AF) return 2; // 韩文
    return 1; // 默认
}
