export interface Disposable {
    dispose(): void | Promise<void>;
    [Symbol.dispose](): void;
    [Symbol.asyncDispose](): void;
}

export interface WidgetLike {
    readonly id: number;
}
