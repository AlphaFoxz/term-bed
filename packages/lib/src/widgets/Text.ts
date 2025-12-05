import { type Pointer } from 'bun:ffi';
import type { RectWidget } from '../extern/define';
import widgets, { type RectWidgetInfoOptions } from '../extern/widgets';
import { RectWidgetInfo } from './common';

export default class Text implements RectWidget {
    #ptr: Pointer | null;
    #refrenceCount: number = 0;
    readonly baseInfo: RectWidgetInfo;
    constructor(text: string, options?: Partial<RectWidgetInfoOptions>) {
        const info = widgets.createRectWidgetInfo({
            x: options?.x || 0,
            y: options?.y || 0,
            width: options?.width || 20,
            height: options?.height || 1,
            zIndex: options?.zIndex || 0,
            visible: options?.visible || true,
        });
        this.baseInfo = new RectWidgetInfo(info);
        this.#ptr = widgets.createTextWidget(text, info);
    }

    get id() {
        return this.baseInfo.id;
    }
    mounted() {
        this.#refrenceCount += 1;
    }
    unmounted() {
        this.#refrenceCount -= 1;
    }

    dispose() {
        if (this.#refrenceCount > 0) {
            return;
        }
        widgets.destroyWidget(this.#ptr);
        this.#ptr = null;
    }
    [Symbol.dispose]() {
        this.dispose();
    }
    [Symbol.asyncDispose]() {
        this.dispose();
    }
}
