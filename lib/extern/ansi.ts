import { dlopen, FFIType, suffix } from 'bun:ffi';
const dllPath = `./term-native/zig-out/bin/tui_app.${suffix}`;
const lib = dlopen(dllPath, {
    resetStyle: { returns: FFIType.void, args: [] },
    showCursor: { returns: FFIType.void, args: [] },
    hideCursor: { returns: FFIType.void, args: [] },
    clearScreen: { returns: FFIType.void, args: [] },
    drawText: { returns: FFIType.void, args: [FFIType.i32, FFIType.i32, FFIType.cstring] },
}).symbols;

export default lib;
