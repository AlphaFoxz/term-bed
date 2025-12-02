import { Deferred } from 'ts-deferred';
import type { Disposable } from './define';
import app, { type LogLevel, type TuiAppOptions } from '../extern/app';
import { EventBus } from '../events';
import path from 'path';
import { type SceneWidgetStyleOptions } from '../extern/widgets';
import Scene from './Scene';
import fs from 'fs';
import { EventType } from '../events/define';
import { appendFile } from 'fs/promises';

class App implements Disposable {
    #ptr: any;
    #deferred = new Deferred<void>();
    #logFileDir: string;

    constructor(options?: TuiAppOptions) {
        const logLevel: LogLevel = options?.logLevel || 'info';
        this.#logFileDir = options?.logFilePath || path.resolve(path.dirname(Bun.main), '');
        const clearLog = options?.clearLog || false;
        const debugMode = options?.debugMode || false;
        if (!fs.existsSync(this.#logFileDir)) {
            fs.mkdirSync(this.#logFileDir);
        }
        if (!fs.existsSync(this.#logFileDir + '/term-bed.log') || clearLog) {
            fs.writeFileSync(this.#logFileDir + '/term-bed.log', '');
        }
        app.setupLogger(this.#logFileDir, logLevel);
    }

    async start() {
        this.#ptr = await app.createApp();
        app.forceRenderApp(this.#ptr);
        EventBus.on(EventType.KeyboardEvent, (data) => {
            appendFile(this.#logFileDir + '/term-front.log', `按键事件：${JSON.stringify(data)}\n`);
            // if (data.char === 'q') {
            this.stop();
            // }
        });
        EventBus.start();
        await this.#deferred.promise;
    }

    async stop() {
        await this.dispose();
        EventBus.stop();
        this.#deferred.resolve();
    }

    createScene(options?: SceneWidgetStyleOptions) {
        return new Scene(options);
    }

    switchScene(scene: Scene): void;
    switchScene(sceneId: number): void;
    switchScene(sceneId: Scene | number) {
        if (sceneId instanceof Scene) {
            sceneId = sceneId.id;
        }
        // app.switchScene(sceneId);
    }

    destroyScene() {}

    async dispose() {
        if (!this.#ptr) return;
        await app.destroyApp(this.#ptr);
        this.#ptr = null;
    }

    [Symbol.dispose]() {
        this.dispose();
    }
    [Symbol.asyncDispose]() {
        this.dispose();
    }
}

export function createApp(options?: TuiAppOptions) {
    return new App(options);
}
