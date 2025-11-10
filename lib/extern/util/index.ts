import { type Pointer, CString } from 'bun:ffi';

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
