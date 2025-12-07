import { it, expect } from 'bun:test';
import { RectWidgetInfo } from '../widgets';

it('RectWidgetInfo', () => {
    const info = new RectWidgetInfo({ x: 1, y: 2, width: 3, height: 4, zIndex: 1, visible: true });
    expect(info.id).toBeGreaterThan(0n);
    expect(info.position).toEqual({ x: 1, y: 2 });
    expect(info.rect).toEqual({ width: 3, height: 4 });
    expect(info.zIndex).toBe(1);
    expect(info.visible).toBe(true);
});
