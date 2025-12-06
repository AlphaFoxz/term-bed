import type { WidgetLike, Disposable, Entity } from '../extern/define';
import app, { type SceneOptions } from '../extern/app';
import { toArrayBuffer, type Pointer } from 'bun:ffi';
import { rgbToRgba } from '../extern/common';

export class SceneInfo implements Entity {
    #dataView: DataView;
    #id: bigint;
    #bgRgba: number;
    #visible: number;
    constructor(ptr: Pointer) {
        const buf = toArrayBuffer(ptr, 0, 8 + 4 + 1);
        const dataView = new DataView(buf);
        this.#dataView = dataView;
        this.#id = dataView.getBigUint64(0, true);
        this.#bgRgba = dataView.getUint32(8, true);
        this.#visible = dataView.getUint8(12);
    }
    get id() {
        return this.#id;
    }
    get bgRgb() {
        return {
            r: this.#bgRgba >> 24,
            g: (this.#bgRgba & 0x00ff0000) >> 16,
            b: (this.#bgRgba & 0x0000ff00) >> 8,
        };
    }
    get bgHexRgb() {
        return this.#bgRgba >> 8;
    }
    get visible() {
        return this.#visible === 1;
    }

    setBgRgb(hexRgb: number): void;
    setBgRgb(hexRgb: string): void;
    setBgRgb(rgbColor: { r: number; g: number; b: number }): void;
    setBgRgb(c: { r: number; g: number; b: number } | string | number) {
        const color = rgbToRgba(c as any);
        this.#dataView.setUint8(8, color);
    }
}

export default class Scene implements Disposable, Entity {
    #ptr: Pointer | null;
    #widgets: WidgetLike[] = [];
    #visible: boolean = false;
    readonly baseInfo: SceneInfo;
    constructor(options?: Partial<SceneOptions>) {
        const baseInfoPtr = app.createSceneInfo({
            visible: options?.visible || false,
            bgHexRgb: options?.bgHexRgb || 0x000000,
        });
        this.baseInfo = new SceneInfo(baseInfoPtr);
        this.#ptr = app.createScene(baseInfoPtr);
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
    get id() {
        return 1n;
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
