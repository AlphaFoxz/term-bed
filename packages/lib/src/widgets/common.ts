import type { Entity } from '../extern/define';
import { toArrayBuffer, type Pointer } from 'bun:ffi';

export class RectWidgetInfo implements Entity {
    // #ptr: Pointer;
    #__dataView: DataView;
    #id: bigint;
    #x: number;
    #y: number;
    #width: number;
    #height: number;
    #zIndex: number;
    #visible: number;

    constructor(ptr: Pointer) {
        // this.#ptr = ptr;
        const buf = toArrayBuffer(ptr, 0, 8 + 4 + 4 + 4 + 1);
        const dataView = new DataView(buf);
        this.#__dataView = dataView;
        this.#id = dataView.getBigUint64(0, true);
        // const position = dataView.getUint32(8, true);
        this.#x = dataView.getUint16(8, true);
        this.#y = dataView.getUint16(8 + 2, true);
        // const rect = dataView.getUint32(8 + 4, true);
        this.#width = dataView.getUint16(8 + 4, true);
        this.#height = dataView.getUint16(8 + 4 + 2, true);
        this.#zIndex = dataView.getInt32(8 + 4 + 4, true);
        this.#visible = dataView.getUint8(8 + 4 + 4 + 4);
    }

    get id() {
        return this.#id;
    }
    get x() {
        return this.#x;
    }
    get y() {
        return this.#y;
    }
    get width() {
        return this.#width;
    }
    get height() {
        return this.#height;
    }
    get zIndex() {
        return this.#zIndex;
    }
    get visible() {
        return this.#visible === 1;
    }
    setX(x: number) {
        this.#__dataView.setUint16(8, x, true);
    }
    setY(y: number) {
        this.#__dataView.setUint16(8 + 2, y, true);
    }
    setWidth(width: number) {
        this.#__dataView.setUint16(8 + 4, width, true);
    }
    setHeight(height: number) {
        this.#__dataView.setUint16(8 + 4 + 2, height, true);
    }
    setVisible(visible: boolean) {
        this.#__dataView.setUint8(8 + 4 + 4 + 1, visible ? 1 : 0);
    }
}
