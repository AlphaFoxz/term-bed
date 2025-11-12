import path from 'path';
import { type Pointer, CString, suffix } from 'bun:ffi';
import Bun from 'bun';

const encoder = new TextEncoder();

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
        dllPath = path.resolve(path.dirname(Bun.main), `tui_app.${suffix}`);
        console.debug('dllPath', dllPath);
    }
    return dllPath;
}
