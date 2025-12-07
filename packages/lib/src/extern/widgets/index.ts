import { dlopen, FFIType, type Pointer } from 'bun:ffi';
import { fetchDllPath, toCstring } from '../../utils/ffi';
import { assertPtr } from '../../utils/ffi';
import type { RectWidgetInfoOptions } from './define';

const lib = dlopen(fetchDllPath(), {
    createRectWidgetInfo: {
        returns: FFIType.pointer,
        args: [FFIType.u16, FFIType.u16, FFIType.u16, FFIType.u16, FFIType.i32, FFIType.u8],
    },
    createTextWidget: {
        returns: FFIType.pointer,
        args: [FFIType.cstring],
    },
    destroyWidget: {
        returns: FFIType.void,
        args: [FFIType.pointer],
    },
}).symbols;

export default {
    createRectWidgetInfo(options: RectWidgetInfoOptions): Pointer {
        return assertPtr(
            lib.createRectWidgetInfo(
                options.x,
                options.y,
                options.width,
                options.height,
                options.zIndex,
                options.visible ? 1 : 0
            )
        );
    },
    createTextWidget(text: string, rectWidgetInfoPtr: Pointer): Pointer {
        return assertPtr(lib.createTextWidget(rectWidgetInfoPtr, toCstring(text)));
    },
    destroyWidget(ptr: Pointer | null): void {
        if (!ptr) return;
        lib.destroyWidget(ptr);
    },
};

export type { RectWidgetInfoOptions };
export { RectWidgetInfo } from './RectWidgetInfo';
