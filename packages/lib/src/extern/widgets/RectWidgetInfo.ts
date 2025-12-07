import { type Pointer, ptr } from 'bun:ffi';
import { useOffsetCounter } from '../../utils/ffi';
import { genId } from '../../utils/gen-id';
import type { Entity } from '../define';
import type { RectWidgetInfoOptions } from './define';

export class RectWidgetInfo implements Entity {
    #dataView: DataView;
    #ptr: Pointer;
    static readonly #OFFSET_COUNTER = useOffsetCounter();
    static readonly OFFSETS = {
        id: this.#OFFSET_COUNTER.mark('u64'),
        position: this.#OFFSET_COUNTER.mark('u32'),
        rect: this.#OFFSET_COUNTER.mark('u32'),
        zIndex: this.#OFFSET_COUNTER.mark('i32'),
        visible: this.#OFFSET_COUNTER.mark('u8'),
    };
    constructor(options: RectWidgetInfoOptions) {
        const OFFSETS = RectWidgetInfo.OFFSETS;
        const buffer = new ArrayBuffer(RectWidgetInfo.#OFFSET_COUNTER.current);
        this.#ptr = ptr(buffer);
        const dataView = new DataView(buffer);
        this.#dataView = dataView;
        dataView.setBigUint64(OFFSETS.id, genId());
        dataView.setUint16(OFFSETS.position, options.x, true);
        dataView.setUint16(OFFSETS.position + 2, options.y, true);
        dataView.setUint16(OFFSETS.rect, options.width, true);
        dataView.setUint16(OFFSETS.rect + 2, options.height, true);
        dataView.setInt32(OFFSETS.zIndex, options.zIndex, true);
        dataView.setUint8(OFFSETS.visible, options.visible ? 1 : 0);
    }

    get id() {
        return this.#dataView.getBigUint64(RectWidgetInfo.OFFSETS.id, true);
    }
    get position() {
        return {
            x: this.#dataView.getUint16(RectWidgetInfo.OFFSETS.position, true),
            y: this.#dataView.getUint16(RectWidgetInfo.OFFSETS.position + 2, true),
        };
    }
    get rect() {
        return {
            width: this.#dataView.getUint16(RectWidgetInfo.OFFSETS.rect, true),
            height: this.#dataView.getUint16(RectWidgetInfo.OFFSETS.rect + 2, true),
        };
    }
    get zIndex() {
        return this.#dataView.getInt32(RectWidgetInfo.OFFSETS.zIndex, true);
    }
    get visible() {
        return this.#dataView.getUint8(RectWidgetInfo.OFFSETS.visible) === 1;
    }

    get ptr() {
        return this.#ptr;
    }

    setPosition(x: number, y: number) {
        this.#dataView.setUint16(RectWidgetInfo.OFFSETS.position, x, true);
        this.#dataView.setUint16(RectWidgetInfo.OFFSETS.position + 2, y, true);
    }
    setRect(width: number, height: number) {
        this.#dataView.setUint16(RectWidgetInfo.OFFSETS.rect, width, true);
        this.#dataView.setUint16(RectWidgetInfo.OFFSETS.rect + 2, height, true);
    }
    setZIndex(zIndex: number) {
        this.#dataView.setInt32(RectWidgetInfo.OFFSETS.zIndex, zIndex, true);
    }
    setVisible(visible: boolean) {
        this.#dataView.setUint8(RectWidgetInfo.OFFSETS.visible, visible ? 1 : 0);
    }
}

export default RectWidgetInfo;
