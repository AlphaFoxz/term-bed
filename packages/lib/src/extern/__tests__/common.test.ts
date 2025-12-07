import { it, expect } from 'bun:test';
import { TerminalFrameArena, rgbToRgba } from '../common';
import stringWidth from 'string-width';

it('FrameArena ascii', () => {
    const arena = new TerminalFrameArena();
    const { ptr, len } = arena.allocString('Hello World!');
    expect(ptr).toBeGreaterThan(0);
    expect(len).toBe(12);
    expect(arena.cursor).toBe(13);
    arena.reset();
    expect(arena.cursor).toBe(0);
});

it('FrameArena chinese', () => {
    const arena = new TerminalFrameArena();
    const { ptr, len } = arena.allocString('你好世界');
    expect(ptr).toBeGreaterThan(0);
    expect(len).toBe(12);
    expect(arena.cursor).toBe(13);
    arena.reset();
    expect(arena.cursor).toBe(0);
});

it('string-width', () => {
    expect(stringWidth('你')).toBe(2);
});

it('rgb to rgba', () => {
    expect(rgbToRgba('123')).toEqual(0x112233ff);
    expect(rgbToRgba('#123')).toEqual(0x112233ff);
    expect(rgbToRgba('112233')).toEqual(0x112233ff);
    expect(rgbToRgba('#112233')).toEqual(0x112233ff);
    expect(rgbToRgba(0x112233)).toEqual(0x112233ff);
    expect(rgbToRgba(0x11, 0x22, 0x33)).toEqual(0x112233ff);
    expect(rgbToRgba({ r: 0x11, g: 0x22, b: 0x33 })).toEqual(0x112233ff);
});
