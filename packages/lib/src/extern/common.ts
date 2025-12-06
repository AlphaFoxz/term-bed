import { type Pointer } from 'bun:ffi';

export function assertPtr(ptr: Pointer | null): Pointer {
    if (!ptr) throw new Error('Invalid pointer');
    return ptr;
}

export function rgbToRgba(hexRgb: number): number;
export function rgbToRgba(hexRgb: string): number;
export function rgbToRgba(rgb: { r: number; g: number; b: number }): number;
export function rgbToRgba(color: { r: number; g: number; b: number } | string | number): number {
    if (typeof color === 'string') {
        color = color.replace('#', '');
        if (color.length === 3) {
            color = color[0]! + color[0] + color[1] + color[1] + color[2] + color[2];
        }
        if (color.length !== 6) {
            throw new Error('Invalid color: ' + color);
        }
        return parseInt(color, 16);
    } else if (typeof color === 'number') {
        return color << 8;
    } else {
        return (color.r << 24) | (color.g << 16) | (color.b << 8);
    }
}
