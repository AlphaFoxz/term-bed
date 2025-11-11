import { type Disposable } from '../extern';
import app from '../extern/app';

export class App implements Disposable {
    #ptr: any;
    constructor() {}

    async startApp() {
        this.#ptr = await app.runApp();
        process.stdin.setRawMode(true);
        process.stdin.resume();
        app.forceRenderApp(this.#ptr);
    }

    async stopApp() {
        await this.dispose();
        process.stdin.setRawMode(false);
        process.stdin.pause();
    }

    async dispose() {
        if (!this.#ptr) return;
        await app.exitApp(this.#ptr);
        this.#ptr = null;
    }

    [Symbol.dispose]() {
        this.dispose();
    }
    [Symbol.asyncDispose]() {
        this.dispose();
    }
}
