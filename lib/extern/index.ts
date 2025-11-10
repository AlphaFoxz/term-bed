export interface Destroyable {
    destroy(): void | Promise<void>;
    [Symbol.dispose](): void;
    [Symbol.asyncDispose](): void;
}
