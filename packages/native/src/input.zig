const std = @import("std");
const builtin = @import("builtin");
const logger = @import("./core/logger.zig");

const mode = @import("./input/mode.zig");
const windows_listener = switch (builtin.os.tag) {
    // See https://github.com/marlersoft/zigwin32/blob/5587b16fa040573846a6bf531301f6206d31a6bf/win32/system/console.zig
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
