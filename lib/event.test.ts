import { it } from 'bun:test';
import { EventBusConsumer, EventBusProducer } from './events';
import { EventType } from './events/define';

it('', async () => {
    if (import.meta.main) {
        const consumer = new EventBusConsumer();
        const producer = new EventBusProducer();

        // 启动消费者
        consumer.start((eventType, data) => {
            const got = `[Event ${EventType[eventType]}]
            ${JSON.stringify(data, (key, value) => {
                if (typeof value === 'bigint') {
                    return value.toString();
                }
                return value;
            })}`;
            console.error(
                `[Event ${EventType[eventType]}]`,
                JSON.stringify(data, (key, value) => {
                    if (typeof value === 'bigint') {
                        return value.toString();
                    }
                    return value;
                })
            );
        });

        // 模拟生产者（实际场景中由 Zig 调用 emit）
        setInterval(() => {
            producer.emitUserLogin(12345n, BigInt(Date.now()));
            producer.emitOrderCreated(99999n, 199.99, 12345n);

            const stats = consumer.getStats();
            console.error(`Queue pending: ${stats.pending}`);
        }, 100);

        await new Promise(() =>
            setTimeout(() => {
                consumer.stop();
                process.exit(0);
            }, 4000)
        );
    }
});
