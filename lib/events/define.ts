export enum EventType {
    KeyboardEvent = 1,
    MouseEvent = 2,
}

export type KeyboardEvent = {
    char: string;
    code: number;
};

export type MouseEvent = {
    amount: number;
    userId: number;
};

export interface EventSchema {
    parse(buffer: ArrayBuffer): any;
}

export type DeferEvent<T> = T extends 1 ? KeyboardEvent : T extends 2 ? MouseEvent : never;
