const std = @import("std");

var writeBuf: [35 * 90]u8 = undefined;
pub var writer: std.fs.File.Writer = undefined;
var writerInit: bool = false;

var readBuf: [35 * 90]u8 = undefined;
pub var reader: std.fs.File.Reader = undefined;
var readerInit: bool = false;

pub fn init() void {
    if (!writerInit) {
        writerInit = true;
        writer = std.fs.File.stdout().writer(&writeBuf);
    }
    if (!readerInit) {
        readerInit = true;
        reader = std.fs.File.stdin().reader(&readBuf);
    }
}

pub fn flushAll() void {
    if (writerInit) {
        writer.interface.flush() catch unreachable;
    }
}
