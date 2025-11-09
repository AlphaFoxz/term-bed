import { dlopen, FFIType, suffix, JSCallback, CString, type Pointer } from 'bun:ffi';
import { appendFile } from 'fs/promises';

const dllPath = `./term-native/zig-out/bin/tui_app.${suffix}`;
console.debug('dll path:', dllPath);
const lib = dlopen(dllPath, {
    runApp: { returns: FFIType.pointer, args: [FFIType.pointer] },
    exitApp: { returns: FFIType.void, args: [FFIType.pointer] },
}).symbols;

const logFilePath = process.cwd() + '/log.log';
Bun.write(logFilePath, '');
/*
info:
error:
debug:
warning: 
*/
const loggerCallback = new JSCallback(
    (ptr: Pointer, length: number) => {
        const timestamp = new Date().toISOString();
        const logEntry = `[${timestamp}] ${new CString(ptr, 0, length).toString()}\n`;
        appendFile(logFilePath, logEntry, { encoding: 'utf-8' });
    },
    { returns: FFIType.void, args: [FFIType.ptr, FFIType.u64] }
);

export default {
    runApp: () => {
        return lib.runApp(loggerCallback.ptr);
    },
    exitApp: async (appPtr: Pointer | null) => {
        lib.exitApp(appPtr);
        const timestamp = new Date().toISOString();
        const logEntry = `[${timestamp}] warning: TuiApp exited with code 0\n`;
        await appendFile(logFilePath, logEntry, { encoding: 'utf-8' });
    },
};
