import { type Pointer } from 'bun:ffi';

export function assertPtr(ptr: Pointer | null): Pointer {
    if (!ptr) throw new Error('Invalid pointer');
    return ptr;
}
