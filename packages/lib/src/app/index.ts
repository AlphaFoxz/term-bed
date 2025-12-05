import type { Disposable } from './define';
import app, { type LogLevel, type TuiAppOptions } from '../extern/app';
import { EventBus } from '../events';
import path from 'path';
import { type SceneWidgetStyleOptions } from '../extern/widgets';
import Scene from './Scene';
import { Logger } from './logger';
import { EventType } from '../events/define';

class App implements Disposable {
    #ptr: any;
    #debugMode = false;
    #scenes: Scene[] = [];

    constructor(options?: TuiAppOptions) {
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

    async start() {
        this.#ptr = await app.createApp();
        app.forceRenderApp(this.#ptr);
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
                await this.stop();
            }
        });
        EventBus.start();
    }

    async stop() {
        await this.dispose();
        EventBus.stop();
        Logger.deinit();
    }

    createScene(options?: SceneWidgetStyleOptions) {
        const scene = new Scene(options);
        this.#scenes.push(scene);
        return scene;
    }

    switchScene(scene: Scene): void;
    switchScene(sceneId: number): void;
    switchScene(sceneId: Scene) {
        const scenes = this.#scenes;
        if (sceneId instanceof Scene) {
            sceneId = sceneId.id;
        }
        // TODO-wong switch scene
        // app.switchScene(sceneId);
    }

    async dispose() {
        if (!this.#ptr) return;
        await app.destroyApp(this.#ptr);
        this.#ptr = null;
    }

    async [Symbol.dispose]() {
        await this.dispose();
    }
    async [Symbol.asyncDispose]() {
        await this.dispose();
    }
}

export function createApp(options?: TuiAppOptions) {
    return new App(options);
}
