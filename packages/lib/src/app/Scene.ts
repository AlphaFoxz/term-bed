import type { Disposable, WidgetLike } from './define';
import widgets, { type SceneWidgetStyleOptions } from '../extern/widgets';

export default class Scene implements Disposable, WidgetLike {
    #id: number = NaN;
    #ptr: any;
    constructor(options?: SceneWidgetStyleOptions) {
        this.#ptr = widgets.createSceneWidget(options);
    }
    get id() {
        if (!this.#id) {
            this.#id = 1;
        }
        return this.#id;
    }
    mount(widget: WidgetLike) {
        // FIXME-wong
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
