import type { Disposable } from './define';
import app, { type LogLevel, type TuiAppOptions } from '../extern/app';
import path from 'path';
import { type SceneWidgetStyleOptions } from '../extern/widgets';
import Scene from './Scene';
import fs from 'fs';

class App implements Disposable {
    #ptr: any;
    constructor(options?: TuiAppOptions) {
        const logLevel: LogLevel = options?.logLevel || 'info';
        const logFileDir: string = options?.logFilePath || path.resolve(path.dirname(Bun.main), '');
        const clearLog = options?.clearLog || false;
        if (!fs.existsSync(logFileDir)) {
            fs.mkdirSync(logFileDir);
        }
        if (!fs.existsSync(logFileDir + '/term-bed.log') || clearLog) {
            fs.writeFileSync(logFileDir + '/term-bed.log', '');
        }
        app.setupLogger(logFileDir, logLevel);
    }

    async start() {
        this.#ptr = await app.createApp();
        process.stdin.setRawMode(true);
        process.stdin.resume();
        app.forceRenderApp(this.#ptr);
    }

    async stop() {
        await this.dispose();
        process.stdin.setRawMode(false);
        process.stdin.pause();
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
