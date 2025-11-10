import { dlopen, FFIType, suffix, type Pointer } from 'bun:ffi';
import { toCstring } from './util';

const dllPath = `./term-native/zig-out/bin/tui_app.${suffix}`;
console.debug('dll path:', dllPath);
const lib = dlopen(dllPath, {
    runApp: { returns: FFIType.pointer, args: [FFIType.cstring] },
    exitApp: { returns: FFIType.void, args: [FFIType.pointer] },
    forceRenderApp: { returns: FFIType.pointer, args: [FFIType.pointer] },
}).symbols;

const logFilePath = process.cwd();

export default {
    runApp: async () => {
        await Bun.write(logFilePath + '/term-bed.log', '');
        return lib.runApp(toCstring(logFilePath));
    },
    exitApp: async (appPtr: Pointer | null) => {
        if (!appPtr) return;
        lib.exitApp(appPtr);
    },
    forceRenderApp: lib.forceRenderApp,
};
