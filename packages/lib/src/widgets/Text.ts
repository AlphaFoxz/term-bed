import type { Disposable, WidgetLike } from '../app/define';
import widgets, { type RectWidgetStyleOptions } from '../extern/widgets';

export default class Text implements Disposable, WidgetLike {
    #id = NaN;
    #ptr: any;
    constructor(text: string, options?: RectWidgetStyleOptions) {
        this.#ptr = widgets.createTextWidget(text, options);
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
