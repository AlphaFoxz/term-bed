import { it, expect } from 'bun:test';
import { rgbToRgba } from '../color';

it('rgb to rgba', () => {
    expect(rgbToRgba('123')).toEqual(0x112233ff);
    expect(rgbToRgba('#123')).toEqual(0x112233ff);
    expect(rgbToRgba('112233')).toEqual(0x112233ff);
    expect(rgbToRgba('#112233')).toEqual(0x112233ff);
    expect(rgbToRgba(0x112233)).toEqual(0x112233ff);
    expect(rgbToRgba(0x11, 0x22, 0x33)).toEqual(0x112233ff);
    expect(rgbToRgba({ r: 0x11, g: 0x22, b: 0x33 })).toEqual(0x112233ff);
});
