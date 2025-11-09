import { createReactive } from '../lib/reactive';
import app from './extern/app';
import ansi from './extern/ansi';
import { mount } from '../lib/renderer';

const encoder = new TextEncoder();
function toCstring(str: string): Uint8Array {
    const bytes = encoder.encode(str);
    const out = new Uint8Array(bytes.length + 1);
    out.set(bytes);
    out[bytes.length] = 0; // null terminator
    return out;
}

const [state, watch] = createReactive({ count: 0 });

const appInstance = app.runApp();

watch(() => render());

const TIPS1 = toCstring(`Press ENTER to increment.`);
const TIPS2 = toCstring(`Press Ctrl+C to exit.`);

function render() {
    ansi.clearScreen();
    ansi.drawText(0, 0, toCstring(`Count: ${state.count}`));
    ansi.drawText(1, 0, TIPS1);
    ansi.drawText(2, 0, TIPS2);
}

mount(render);

process.stdin.setRawMode(true);
process.stdin.resume();
process.stdin.on('data', async (data) => {
    if (data.toString() === '\r') {
        state.count++;
    } else if (data.toString() === '+') {
        state.count++;
    } else if (data.toString() === '-') {
        state.count--;
    }
    if (data.toString() === '\u0003') {
        // Ctrl+C
        await app.exitApp(appInstance);
        process.exit(0);
    }
});
