import { type Disposable } from '../extern';
import widgets, { type TextWidgetOptions } from '../extern/widgets';

export default class Text implements Disposable {
    #ptr: any;
    constructor(options: TextWidgetOptions) {
        this.#ptr = widgets.createTextWidget(options);
    }

    private render() {}

    dispose() {
        if (!this.#ptr) return;
        widgets.destroyWidget(this.#ptr);
    }

    [Symbol.dispose]() {
        this.dispose();
    }
    [Symbol.asyncDispose]() {
        this.dispose();
    }
}
