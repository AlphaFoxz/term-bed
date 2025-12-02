import eventLib from '../extern/events';
import { toArrayBuffer } from 'bun:ffi';
import { EventType, type EventSchema, type MouseEvent, type KeyboardEvent, type DeferEvent } from './define';

class KeyboardEventSchema implements EventSchema {
    parse(buffer: ArrayBuffer) {
        const view = new DataView(buffer);
        return {
            char: view.getUint16(0, true),
            code: view.getUint32(2, true),
            // timestamp: Number(view.getBigInt64(8, true)),
        };
    }
}

class MouseEventSchema implements EventSchema {
    parse(buffer: ArrayBuffer) {
        const view = new DataView(buffer);
        return {
            amount: view.getFloat64(8, true),
            userId: view.getBigUint64(16, true),
        };
    }
}

const schemaRegistry = new Map<EventType, EventSchema>([
    [EventType.KeyboardEvent, new KeyboardEventSchema()],
    [EventType.MouseEvent, new MouseEventSchema()],
]);

export class EventBus {
    static #running = false;
    static #handlers: Record<number, ((data: any) => void)[]> = {};

    static start() {
        this.#running = true;

        const consume = () => {
            if (!this.#running) {
                return;
            }
            const slotPtr = eventLib.event_bus_poll();

            if (slotPtr !== null) {
                try {
                    // 读取事件头（前12字节）
                    const headerBuf = toArrayBuffer(slotPtr, 0, 12);
                    const headerView = new DataView(headerBuf);
                    const eventType = headerView.getUint16(0, true);
                    const payloadLen = headerView.getUint16(2, true);
                    const sequence = headerView.getBigUint64(4, true);

                    // 读取负载数据
                    const payloadBuf = toArrayBuffer(slotPtr, 12, payloadLen);

                    // 解析成 JSON
                    const schema = schemaRegistry.get(eventType as EventType);
                    if (schema) {
                        const handlers = this.#handlers[eventType];
                        if (handlers) {
                            const jsonData = schema.parse(payloadBuf);
                            for (const handler of handlers) {
                                handler(jsonData);
                            }
                        }
                    } else {
                        console.warn(`Unknown event type: ${eventType}`);
                    }

                    // 确认读取
                    eventLib.event_bus_commit();
                } catch (err) {
                    console.error('Event parse error:', err);
                }
            }
            setImmediate(consume);
        };
        consume();
    }

    static stop() {
        this.#running = false;
    }

    static on(eventType: EventType.MouseEvent, handler: (data: MouseEvent) => void): void;
    static on(eventType: EventType.KeyboardEvent, handler: (data: KeyboardEvent) => void): void;
    static on(eventType: EventType, handler: (data: any) => void) {
        if (!this.#handlers[eventType]) {
            this.#handlers[eventType] = [];
        }
        this.#handlers[eventType].push(handler);
    }
    static off(eventType: EventType, handler: (data: any) => void) {
        const handlers = this.#handlers[eventType];
        if (handlers) {
            const index = handlers.indexOf(handler);
            if (index !== -1) {
                handlers.splice(index, 1);
            }
        }
    }
}
