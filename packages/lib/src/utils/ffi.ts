import path from 'path';
import fs from 'fs';
import { type Pointer, CString, suffix } from 'bun:ffi';
import type { DataType } from '../extern/define';

const encoder = new TextEncoder('utf-8');

export function assertPtr(ptr: Pointer | null): Pointer {
    if (!ptr) throw new Error('Invalid pointer');
    return ptr;
}

export function useOffsetCounter() {
    let currentOffset = 0;
    function mark(type: DataType): number;
    function mark(bytes: number): number;
    function mark(param: DataType | number): number {
        let bytes = 0;
        if (typeof param === 'number') {
            bytes = param;
        } else {
            const bits = parseInt(param.substring(1));
            bytes = bits / 8 + (bits % 8 > 0 ? 1 : 0);
        }
        const offset = currentOffset;
        currentOffset += bytes;
        return offset;
    }
    return {
        get current() {
            return currentOffset;
        },
        mark,
    };
}

export function toCstring(str: string): Uint8Array {
    const bytes = encoder.encode(str);
    const out = new Uint8Array(bytes.length + 1);
    out.set(bytes);
    out[bytes.length] = 0; // null terminator
    return out;
}

export function cToString(ptr: Pointer, length: number): string {
    return new CString(ptr, 0, length).toString();
}

let dllPath: string;
export function fetchDllPath() {
    if (!dllPath) {
        dllPath = path.resolve(path.dirname(Bun.main), `term_bed.${suffix}`);
        if (fs.existsSync(dllPath)) {
            return dllPath;
        }
        dllPath = path.resolve(import.meta.dir, `term_bed.${suffix}`);
        if (fs.existsSync(dllPath)) {
            return dllPath;
        }
        // TODO-wong: 从PATH中查找
    }
    return dllPath;
}
