const std = @import("std");
pub const clear = @import("./clear.zig");
pub const cursor = @import("./cursor.zig");
pub const format = @import("./format.zig");
pub const style = @import("./style.zig");
pub const terminal = @import("./terminal.zig");

pub fn writeAll(writer: anytype, str: []const u8) !void {
    try writer.writeAll(str);
}

pub fn writeAllAndFlush(writer: anytype, str: []const u8) !void {
    try writeAll(writer, str);
    try writer.flush();
}

pub fn print(writer: anytype, comptime fmt: []const u8, args: anytype) !void {
    try writer.print(fmt, args);
}

pub fn printAndFlush(writer: anytype, comptime fmt: []const u8, args: anytype) !void {
    try print(writer, fmt, args);
    try writer.flush();
}
