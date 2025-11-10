const std = @import("std");
const logger = @import("./core/logger.zig");

pub fn outOfMemory() void {
    logger.logError("Out of memory");
    std.process.exit(101);
}
