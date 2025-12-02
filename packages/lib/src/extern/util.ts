import path from 'path';
import fs from 'fs';
import { type Pointer, CString, suffix } from 'bun:ffi';

const encoder = new TextEncoder('utf-8');

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
