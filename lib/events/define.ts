export enum EventType {
    UserLogin = 1,
    OrderCreated = 2,
    PaymentReceived = 3,
}

export interface EventSchema {
    parse(buffer: ArrayBuffer): any;
}
