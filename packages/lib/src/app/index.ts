import type { Disposable } from '../extern/define';
import app, { type LogLevel, type TuiAppOptions, type SceneOptions } from '../extern/app';
import { EventBus } from '../events';
import path from 'path';
import Scene from './Scene';
import { Logger } from '../common/logger';
import { EventType } from '../events/define';
import { type Pointer } from 'bun:ffi';

class App implements Disposable {
    #ptr: Pointer | null = null;
    #debugMode = false;
    #scenes: Scene[] = [];
    #running = false;

    constructor(options?: Partial<TuiAppOptions>) {
        const logLevel: LogLevel = options?.logLevel || 'info';
        const logFileDir = options?.logFilePath || path.dirname(Bun.main);
        const backendLogName = options?.backendLogName || 'term_bed-backend.log';
        const frontendLogName = options?.frontendLogName || 'term_bed-frontend.log';
        const clearLog = options?.clearLog || false;
        Logger.init({
            logFileDir,
            logLevel,
            clearLog,
            frontendLogName,
            backendLogName,
        });
        this.#debugMode = options?.debugMode || false;
        app.setupLogger(logFileDir, backendLogName, logLevel);
    }

    start() {
        this.#ptr = app.createApp();
        app.renderApp(this.#ptr);
        if (this.#debugMode) {
            EventBus.on(EventType.KeyboardEvent, async (data) => {
                Logger.logDebug(`按键事件：${JSON.stringify(data)}`);
            });
            EventBus.on(EventType.WheelEvent, async (data) => {
                Logger.logDebug(`鼠标滚轮事件：${JSON.stringify(data)}`);
            });
            EventBus.on(EventType.MouseEvent, async (data) => {
                Logger.logDebug(`鼠标事件：${JSON.stringify(data)}`);
            });
        }
        EventBus.on(EventType.KeyboardEvent, async (data) => {
            if (data.key === 'q' || data.key === 'Q') {
                setTimeout(() => {
                    this.stop();
                });
            }
        });
        EventBus.start();
        const consume = () => {
            if (!this.#running) {
                return;
            }
            // app.renderApp(this.#ptr);
            setImmediate(consume);
        };
        consume();
    }

    stop() {
        this.dispose();
        EventBus.stop();
        Logger.deinit();
    }

    createScene(options?: Partial<SceneOptions>) {
        const scene = new Scene(options);
        this.#scenes.push(scene);
        return scene;
    }

    switchScene(scene: Scene) {
        for (const s of this.#scenes) {
            s.setVisible(s === scene);
        }
    }

    dispose() {
        if (!this.#ptr) return;
        app.destroyApp(this.#ptr);
        this.#ptr = null;
    }

    [Symbol.dispose]() {
        this.dispose();
    }
    [Symbol.asyncDispose]() {
        this.dispose();
    }
}

let appInstance: App | undefined = undefined;
async function onUnexceptExit(err: unknown) {
    let errStr = 'Unexcept exit';
    if (!err) {
    } else if (typeof err === 'object') {
        errStr += errStr = JSON.stringify(err);
    } else {
        errStr += err;
    }
    Logger.logError(errStr);
    await new Promise((resolve) => setTimeout(resolve));
    if (appInstance) {
        appInstance.stop();
    }
}
process.on('unhandledRejection', onUnexceptExit);
process.on('uncaughtException', onUnexceptExit);

export function createApp(options?: Partial<TuiAppOptions>) {
    return new App(options);
}
