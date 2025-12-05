import { dlopen, FFIType, type Pointer } from 'bun:ffi';
import { fetchDllPath, toCstring } from './util';

const lib = dlopen(fetchDllPath(), {
    createSceneWidget: {
        returns: FFIType.pointer,
        args: [FFIType.bool, FFIType.u32],
    },
    createTextWidget: {
        returns: FFIType.pointer,
        args: [FFIType.u16, FFIType.u16, FFIType.u16, FFIType.u16, FFIType.bool, FFIType.cstring],
    },
    destroyWidget: {
        returns: FFIType.void,
        args: [FFIType.pointer],
    },
}).symbols;

export interface RectWidgetStyleOptions {
    x?: number;
    y?: number;
    width?: number;
    height?: number;
    visible?: boolean;
}

export interface SceneWidgetStyleOptions extends Pick<RectWidgetStyleOptions, 'visible'> {
    bgHexRgb?: number;
}

export default {
    createSceneWidget: (options?: SceneWidgetStyleOptions) => {
        return lib.createSceneWidget(options?.visible || true, options?.bgHexRgb || 0x000);
    },
    createTextWidget: (text: string, options?: RectWidgetStyleOptions): Pointer | null => {
        return lib.createTextWidget(
            options?.x || 0,
            options?.y || 0,
            options?.width || 20,
            options?.height || 1,
            options?.visible || true,
            toCstring(text)
        );
    },
    destroyWidget: lib.destroyWidget,
};
