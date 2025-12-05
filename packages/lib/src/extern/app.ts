import { dlopen, FFIType, type Pointer } from 'bun:ffi';
import { fetchDllPath, toCstring } from './util';

const lib = dlopen(fetchDllPath(), {
    setupLogger: {
        returns: FFIType.void,
        args: [FFIType.cstring, FFIType.cstring, FFIType.i32],
    },
    createApp: { returns: FFIType.pointer, args: [] },
    destroyApp: { returns: FFIType.void, args: [FFIType.pointer] },
    forceRenderApp: { returns: FFIType.pointer, args: [FFIType.pointer] },
}).symbols;

export type LogLevel = 'debug' | 'info' | 'warning' | 'error';

export interface TuiAppOptions {
    logLevel?: LogLevel;
    logFilePath?: string;
    frontendLogName?: string;
    backendLogName?: string;
    clearLog?: boolean;
    debugMode?: boolean;
}

export default {
    setupLogger: (logFileDir: string, backendLogName: string, logLevel: LogLevel) => {
        let logLvl: number;
        switch (logLevel) {
            case 'debug':
                logLvl = 0;
                break;
            case 'info':
                logLvl = 1;
                break;
            case 'warning':
                logLvl = 2;
                break;
            case 'error':
                logLvl = 3;
                break;
        }
        lib.setupLogger(toCstring(logFileDir), toCstring(backendLogName), logLvl);
    },
    createApp: async () => {
        return lib.createApp();
    },
    destroyApp: async (appPtr: Pointer | null) => {
        if (!appPtr) return;
        lib.destroyApp(appPtr);
    },
    forceRenderApp: lib.forceRenderApp,
};
