import type { WidgetLike, Disposable } from '../extern/define';
import app, { type SceneOptions } from '../extern/app';
import { type Pointer } from 'bun:ffi';

export default class Scene implements Disposable {
    #ptr: Pointer | null;
    #widgets: WidgetLike[] = [];
    #visible: boolean = false;
    constructor(options?: Partial<SceneOptions>) {
        this.#ptr = app.createScene({
            visible: options?.visible || false,
            bgHexRgb: options?.bgHexRgb || 0x000000,
        });
    }
    setVisible(visible: boolean) {
        this.#visible = visible;
    }
    get visible() {
        return this.#visible;
    }
    mount(widget: WidgetLike) {
        this.#widgets.push(widget);
        widget.mounted();
        return this;
    }
    unmount(widget: WidgetLike) {
        const index = this.#widgets.indexOf(widget);
        if (index >= 0) {
            this.#widgets[index]?.unmounted();
            this.#widgets.splice(this.#widgets.indexOf(widget), 1);
        }
    }
    dispose() {
        this.#widgets.length = 0;
        app.destroyScene(this.#ptr);
        this.#ptr = null;
    }
    [Symbol.dispose]() {
        this.dispose();
    }
    [Symbol.asyncDispose]() {
        this.dispose();
    }
}
