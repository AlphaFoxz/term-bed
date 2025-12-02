const std = @import("std");
const builtin = @import("builtin");
const logger = @import("./core/logger.zig");

const mode = @import("./input/mode.zig");
const windows_listener = switch (builtin.os.tag) {
    .windows => @import("./input/windows_listener.zig"),
    .linux, .macos, .freebsd, .netbsd, .openbsd => @import("./input/posix_listener.zig"),
    else => unsupportedOS(),
};
// const mouse_listener = @import("./input/mouse_listener.zig");

pub fn startListening() void {
    mode.switchMouseInputMode();
    switch (builtin.os.tag) {
        .windows => windows_listener.start(),
        .linux, .macos, .freebsd, .netbsd, .openbsd => {},
        else => unsupportedOS(),
    }
}

pub fn stopListening() void {
    defer mode.switchDefaultInputMode();
    switch (builtin.os.tag) {
        .windows => windows_listener.stop(),
        .linux, .macos, .freebsd, .netbsd, .openbsd => {},
        else => unsupportedOS(),
    }
}

fn unsupportedOS() noreturn {
    logger.logError("Unsupported OS");
    std.process.exit(1);
}
