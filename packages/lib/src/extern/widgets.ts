import { dlopen, FFIType, type Pointer, toArrayBuffer } from 'bun:ffi';
import { fetchDllPath, toCstring } from './util';
import { assertPtr } from './common';

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

export interface RectWidgetInfoOptions {
    x: number;
    y: number;
    width: number;
    height: number;
    zIndex: number;
    visible: boolean;
}

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
