const std = @import("std");
const logger = @import("./logger.zig");

pub fn outOfMemory() noreturn {
    logger.logError("Out of memory");
    std.process.exit(101);
}
