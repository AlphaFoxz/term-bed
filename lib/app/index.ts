import app from '../extern/app';

export class App {
    #ptr: any;
    constructor() {}

    startApp() {
        this.#ptr = app.runApp();
    }

    stopApp() {
        app.exitApp(this.#ptr);
    }

    [Symbol.dispose]() {
        this.stopApp();
    }
}
