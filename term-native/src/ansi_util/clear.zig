const esc = "\x1B";
const csi = esc ++ "[";

pub fn clearCurrentLine(writer: anytype) !void {
    try writer.writeAll(csi ++ "2K");
}

pub fn clearCurrentLineAndFlush(writer: anytype) !void {
    try clearCurrentLine(writer);
    try writer.flush();
}

pub fn clearFromCursorToLineBeginning(writer: anytype) !void {
    try writer.writeAll(csi ++ "1K");
}

pub fn clearFromCursorToLineBeginningAndFlush(writer: anytype) !void {
    try clearFromCursorToLineBeginning(writer);
    try writer.flush();
}

pub fn clearFromCursorToLineEnd(writer: anytype) !void {
    try writer.writeAll(csi ++ "K");
}

pub fn clearFromCursorToLineEndAndFlush(writer: anytype) !void {
    try clearFromCursorToLineEnd(writer);
    try writer.flush();
}

pub fn clearScreen(writer: anytype) !void {
    try writer.writeAll(csi ++ "2J");
}

pub fn clearScreenAndFlush(writer: anytype) !void {
    try clearScreen(writer);
    try writer.flush();
}

pub fn clearFromCursorToScreenBeginning(writer: anytype) !void {
    try writer.writeAll(csi ++ "1J");
}

pub fn clearFromCursorToScreenBeginningAndFlush(writer: anytype) !void {
    try clearFromCursorToScreenBeginning(writer);
    try writer.flush();
}

pub fn clearFromCursorToScreenEnd(writer: anytype) !void {
    try writer.writeAll(csi ++ "J");
}

pub fn clearFromCursorToScreenEndAndFlush(writer: anytype) !void {
    try clearFromCursorToScreenEnd(writer);
    try writer.flush();
}
