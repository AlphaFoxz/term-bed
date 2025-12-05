import { dlopen, FFIType, type Pointer } from 'bun:ffi';
import { fetchDllPath, toCstring } from './util';
import { assertPtr } from './common';

const lib = dlopen(fetchDllPath(), {
    setupLogger: {
        returns: FFIType.void,
        args: [FFIType.cstring, FFIType.cstring, FFIType.i32],
    },
    createApp: { returns: FFIType.pointer, args: [] },
    destroyApp: { returns: FFIType.void, args: [FFIType.pointer] },
    createScene: {
        returns: FFIType.pointer,
        args: [FFIType.bool, FFIType.u32],
    },
    destroyScene: {
        returns: FFIType.void,
        args: [FFIType.pointer],
    },
    forceRenderApp: { returns: FFIType.pointer, args: [FFIType.pointer] },
}).symbols;

export type LogLevel = 'debug' | 'info' | 'warning' | 'error';

export interface TuiAppOptions {
    logLevel: LogLevel;
    logFilePath: string;
    frontendLogName: string;
    backendLogName: string;
    clearLog: boolean;
    debugMode: boolean;
}

export interface SceneOptions {
    visible: boolean;
    bgHexRgb: number;
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
    createApp(): Pointer {
        return assertPtr(lib.createApp());
    },
    destroyApp(appPtr: Pointer | null) {
        if (!appPtr) {
            return;
        }
        lib.destroyApp(appPtr);
    },
    createScene(options: SceneOptions): Pointer {
        return assertPtr(lib.createScene(options.visible, options.bgHexRgb));
    },
    destroyScene(scenePtr: Pointer | null) {
        if (!scenePtr) {
            return;
        }
        lib.destroyScene(scenePtr);
    },
    forceRenderApp: lib.forceRenderApp,
};
