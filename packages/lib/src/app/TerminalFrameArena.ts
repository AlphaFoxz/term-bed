import { type Pointer, ptr } from 'bun:ffi';

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

export default TerminalFrameArena;
