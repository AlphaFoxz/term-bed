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
    createSceneInfo: {
        returns: FFIType.pointer,
        args: [FFIType.u32, FFIType.u8],
    },
    createScene: {
        returns: FFIType.pointer,
        args: [FFIType.pointer],
    },
    destroyScene: {
        returns: FFIType.void,
        args: [FFIType.pointer],
    },
    renderApp: { returns: FFIType.pointer, args: [FFIType.pointer] },
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
    createSceneInfo(options: SceneOptions): Pointer {
        return assertPtr(lib.createSceneInfo(options.bgHexRgb, options.visible ? 1 : 0));
    },
    createScene(infoPtr: Pointer): Pointer {
        return assertPtr(lib.createScene(infoPtr));
    },
    destroyScene(scenePtr: Pointer | null) {
        lib.destroyScene(assertPtr(scenePtr));
    },
    renderApp(ptr: Pointer | null) {
        lib.renderApp(assertPtr(ptr));
    },
};
