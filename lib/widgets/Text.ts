import type { Disposable, WidgetLike } from '../app/define';
import widgets, { type TextWidgetStyleOptions } from '../extern/widgets';

export default class Text implements Disposable, WidgetLike {
    #id = NaN;
    #ptr: any;
    constructor(options: TextWidgetStyleOptions) {
        this.#ptr = widgets.createTextWidget(options);
    }
    get id() {
        // FIXME-wong
        return 1;
    }

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
