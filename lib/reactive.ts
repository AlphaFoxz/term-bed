type Callback = () => void;

export function createReactive<T extends object>(obj: T): [T, (cb: Callback) => void] {
    const cbs: Callback[] = [];
    const proxy = new Proxy(obj, {
        set(target, key, value) {
            if (target[key as keyof T] !== value) {
                target[key as keyof T] = value;
                cbs.forEach((cb) => cb());
            }
            return true;
        },
    });
    // 返回 proxy 和注册回调的函数
    return [proxy, (cb: Callback) => cbs.push(cb)];
}
