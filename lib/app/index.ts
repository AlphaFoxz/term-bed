import { type Destroyable } from '../extern';
import app from '../extern/app';

export class App implements Destroyable {
    #ptr: any;
    constructor() {}

    async startApp() {
        this.#ptr = await app.runApp();
        process.stdin.setRawMode(true);
        // process.stdin.resume();
        app.forceRenderApp(this.#ptr);
    }

    async stopApp() {
        await this.destroy();
        process.stdin.setRawMode(false);
        // process.stdin.pause();
    }

    async destroy() {
        if (!this.#ptr) return;
        await app.exitApp(this.#ptr);
        this.#ptr = null;
    }

    [Symbol.dispose]() {
        this.destroy();
    }
    [Symbol.asyncDispose]() {
        this.destroy();
    }
}
