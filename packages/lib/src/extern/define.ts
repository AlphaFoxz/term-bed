export interface Disposable {
    dispose(disposeWidgets?: boolean): void | Promise<void>;
    [Symbol.dispose](): void;
    [Symbol.asyncDispose](): void;
}

export interface Entity {
    readonly id: bigint;
    setId?: never;
}

export interface Mountable {
    mounted(): void;
    unmounted(): void;
}

export interface WidgetLike extends Disposable, Entity, Mountable {}

export interface RectWidget extends WidgetLike {
    readonly baseInfo: Entity;
}
