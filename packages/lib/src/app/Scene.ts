import type { WidgetLike } from './define';
import widgets, { type SceneWidgetStyleOptions } from '../extern/widgets';

export default class Scene implements WidgetLike {
    #id: number = NaN;
    #ptr: any;
    #widgets: WidgetLike[] = [];
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
        this.#widgets.push(widget);
        // FIXME-wong
        return this;
    }
    unmount(widget: WidgetLike) {
        const index = this.#widgets.indexOf(widget);
        if (index >= 0) {
            this.#widgets.splice(this.#widgets.indexOf(widget), 1);
        }
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
