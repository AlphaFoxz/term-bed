import { expect, it } from 'bun:test';
import Text from '../Text';

it('text widget', () => {
    let text;
    try {
        text = new Text('', { x: 1, y: 2, width: 3, height: 4, visible: true });
        expect(text.id).toBeGreaterThan(0n);
        // expect(text.baseInfo).toEqual({ x: 1, y: 2, width: 3, height: 4, visible: 1 });
        expect(text.baseInfo.x).toBe(1);
        expect(text.baseInfo.y).toBe(2);
        expect(text.baseInfo.width).toBe(3);
        expect(text.baseInfo.height).toBe(4);
        expect(text.baseInfo.visible).toBe(true);
    } finally {
        text?.dispose();
    }
});
