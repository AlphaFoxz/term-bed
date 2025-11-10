import { type Destroyable } from '../extern';
import widgets, { type TextWidgetOptions } from '../extern/widgets';

export default class Text implements Destroyable {
    #ptr: any;
    constructor(options: TextWidgetOptions) {
        this.#ptr = widgets.createTextWidget(options);
    }

    private render() {}

    destroy() {
        if (!this.#ptr) return;
        widgets.destroyWidget(this.#ptr);
    }

    [Symbol.dispose]() {
        this.destroy();
    }
    [Symbol.asyncDispose]() {
        this.destroy();
    }
}
