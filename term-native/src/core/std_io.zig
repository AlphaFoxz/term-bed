const std = @import("std");

pub fn getStdWriter() @TypeOf(std.io.getStdOut().writer()) {
    return std.io.getStdOut().writer();
}

pub fn getStdReader() @TypeOf(std.io.getStdIn().reader()) {
    return std.io.getStdIn().reader();
}
