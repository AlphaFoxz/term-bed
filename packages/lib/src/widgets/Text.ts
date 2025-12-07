import { type Pointer } from 'bun:ffi';
import type { RectWidget } from '../extern/define';
import widgets, { RectWidgetInfo, type RectWidgetInfoOptions } from '../extern/widgets/index';

export default class Text implements RectWidget {
    #ptr: Pointer;
    #refrenceCount: number = 0;
    readonly baseInfo: RectWidgetInfo;
    constructor(text: string, options?: Partial<RectWidgetInfoOptions>) {
        // const info = widgets.createRectWidgetInfo({
        //     x: options?.x || 0,
        //     y: options?.y || 0,
        //     width: options?.width || 20,
        //     height: options?.height || 1,
        //     zIndex: options?.zIndex || 0,
        //     visible: options?.visible || true,
        // });
        const info = new RectWidgetInfo({
            x: options?.x || 0,
            y: options?.y || 0,
            width: options?.width || 20,
            height: options?.height || 1,
            zIndex: options?.zIndex || 0,
            visible: options?.visible || true,
        });
        this.baseInfo = info;
        this.#ptr = widgets.createTextWidget(text, info.ptr);
    }

    get id() {
        return this.baseInfo.id;
    }
    get ptr() {
        return this.#ptr;
    }
    mounted() {
        this.#refrenceCount += 1;
    }
    unmounted() {
        this.#refrenceCount -= 1;
    }
}
