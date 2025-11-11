export interface Disposable {
    dispose(): void | Promise<void>;
    [Symbol.dispose](): void;
    [Symbol.asyncDispose](): void;
}
