import { dlopen, FFIType } from 'bun:ffi';
import { toCstring, fetchDllPath } from './util';

const lib = dlopen(fetchDllPath(), {
    resetStyle: { returns: FFIType.void, args: [] },
    showCursor: { returns: FFIType.void, args: [] },
    hideCursor: { returns: FFIType.void, args: [] },
    clearScreen: { returns: FFIType.void, args: [] },
    drawText: { returns: FFIType.void, args: [FFIType.i32, FFIType.i32, FFIType.cstring] },
}).symbols;

export default {
    resetStyle: lib.resetStyle,
    showCursor: lib.showCursor,
    hideCursor: lib.hideCursor,
    clearScreen: lib.clearScreen,
    drawText: (x: number, y: number, text: string) => {
        lib.drawText(x, y, toCstring(text));
    },
};
