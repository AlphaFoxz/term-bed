import { it, expect } from 'bun:test';
import stringWidth from 'string-width';
import { useOffsetCounter } from '../ffi';

it('offsetCounter', () => {
    const counter = useOffsetCounter();
    expect(counter.current).toBe(0);
    expect(counter.mark('u64')).toBe(0);
    expect(counter.mark(4)).toBe(8);
    expect(counter.mark(2)).toBe(12);
    expect(counter.current).toBe(14);
});

it('string-width', () => {
    expect(stringWidth('你')).toBe(2);
});
