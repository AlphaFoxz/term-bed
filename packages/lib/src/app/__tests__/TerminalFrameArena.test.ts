import { it, expect } from 'bun:test';
import TerminalFrameArena from '../TerminalFrameArena';

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
