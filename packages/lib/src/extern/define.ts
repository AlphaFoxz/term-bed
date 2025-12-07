import type { Pointer } from 'bun:ffi';

export interface Disposable {
    dispose(disposeWidgets?: boolean): void | Promise<void>;
    [Symbol.dispose](): void;
    [Symbol.asyncDispose](): void;
}

export interface Entity {
    readonly id: bigint;
    readonly ptr: Pointer;
    setId?: never;
    setPtr?: never;
}

export interface Mountable {
    mounted(): void;
    unmounted(): void;
}

export interface WidgetLike extends Entity, Mountable {}

export interface RectWidget extends WidgetLike {
    readonly baseInfo: Entity;
}

export type DataType = 'u8' | 'i8' | 'u16' | 'i16' | 'u32' | 'i32' | 'u64' | 'i64' | 'f32' | 'f64';
