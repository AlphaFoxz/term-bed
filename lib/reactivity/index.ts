import { type Ref, customRef } from '@vue/reactivity';

interface TuiRef<T = any, S = T> extends Ref<T, S> {
    // close(): void;
}

export function ref<T>(value: T): TuiRef<T, T> {
    const innerRef = customRef((track, trigger) => {
        return {
            get() {
                track();
                return value;
            },
            set(newValue) {
                value = newValue;
                trigger();
            },
            clear() {},
        };
    });
    return innerRef;
}
