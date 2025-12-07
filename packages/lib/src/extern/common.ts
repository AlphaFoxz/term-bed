import { type Pointer, ptr } from 'bun:ffi';

export function assertPtr(ptr: Pointer | null): Pointer {
    if (!ptr) throw new Error('Invalid pointer');
    return ptr;
}

export function rgbToRgba(hexRgb: number): number;
export function rgbToRgba(r: number, g: number, b: number): number;
export function rgbToRgba(hexRgb: string): number;
export function rgbToRgba(rgb: { r: number; g: number; b: number }): number;
export function rgbToRgba(
    color: { r: number; g: number; b: number } | string | number,
    g?: number,
    b?: number
): number {
    if (typeof color === 'string') {
        color = color.replace('#', '');
        if (color.length === 3) {
            color = color[0]! + color[0] + color[1] + color[1] + color[2] + color[2];
        }
        if (color.length !== 6) {
            throw new Error('Invalid color: ' + color);
        }
        return (parseInt(color, 16) << 8) | 0xff;
    } else if (typeof color === 'number') {
        if (g !== undefined && b !== undefined) {
            return (color << 24) | (g << 16) | (b << 8) | 0xff;
        }
        return (color << 8) | 0xff;
    } else {
        return (color.r << 24) | (color.g << 16) | (color.b << 8) | 0xff;
    }
}

export class TerminalFrameArena {
    readonly size: number;
    #buffer: Uint8Array;
    #ptr: Pointer;
    #cursor: number = 0;
    #encoder = new TextEncoder('utf-8');
    constructor(size: number = 1024 * 1024) {
        this.size = size;
        this.#buffer = new Uint8Array(size);
        this.#ptr = ptr(this.#buffer);
    }

    get cursor() {
        return this.#cursor;
    }

    reset() {
        this.#cursor = 0;
    }

    allocString(str: string) {
        const remaining = this.size - this.#cursor;
        if (remaining <= 1) throw new Error('FrameArena: out of memory');

        const dest = this.#buffer.subarray(this.#cursor, this.size - 1); // 留一个位置给 \0

        const { written } = this.#encoder.encodeInto(str, dest);

        this.#buffer[this.#cursor + written] = 0;

        const strPtr = (this.#ptr + this.#cursor) as Pointer;
        const strLen = written; // Zig slice 长度不包含 \0

        this.#cursor += written + 1;

        return { ptr: strPtr, len: strLen };
    }
}
