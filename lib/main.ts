import { createReactive } from '../lib/reactive';
import app from './extern/app';
import ansi from './extern/ansi';
import { mount } from '../lib/renderer';

const [state, watch] = createReactive({ count: 0 });

const appInstance = app.runApp();

watch(() => render());

const TIPS1 = `Press ENTER to increment.`;
const TIPS2 = `Press Ctrl+C to exit.`;

function render() {
    ansi.drawText(0, 0, `Count: ${state.count.toString()}`.padEnd(20, ' '));
    ansi.drawText(0, 1, TIPS1);
    ansi.drawText(0, 2, TIPS2);
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
