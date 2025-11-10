import { dlopen, FFIType, suffix, type Pointer } from 'bun:ffi';
import { toCstring } from './util';

const dllPath = `./term-native/zig-out/bin/tui_app.${suffix}`;
const lib = dlopen(dllPath, {
    createTextWidget: {
        returns: FFIType.pointer,
        args: [FFIType.cstring, FFIType.u16, FFIType.u16, FFIType.u16, FFIType.u16],
    },
}).symbols;

export interface RectWidgetOptions {
    x?: number;
    y?: number;
    width: number;
    height: number;
}

export interface TextWidgetOptions extends RectWidgetOptions {
    text: string;
}

export default {
    createTextWidget: (options: TextWidgetOptions): Pointer | null => {
        return lib.createTextWidget(
            options.x || 0,
            options.y || 0,
            options.width,
            options.height,
            toCstring(options.text)
        );
    },
};
