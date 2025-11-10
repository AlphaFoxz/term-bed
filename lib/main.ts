import { App } from './app';
import Text from './widgets/Text';

const app = new App();

const counter = new Text({
    x: 0,
    y: 0,
    width: 20,
    height: 1,
    text: 'Count: 0',
});
const TIPS1 = new Text({
    x: 0,
    y: 0,
    width: 20,
    height: 1,
    text: 'Press - / + to change count.',
});
const TIPS2 = new Text({
    x: 0,
    y: 1,
    width: 20,
    height: 1,
    text: `Press Ctrl+C to exit.`,
});
app.startApp();

let count = 0;
process.stdin.on('data', async (data) => {
    const input = data.toString().trim();
    if (input === '-') count -= 1;
    if (input === '+') count += 1;
    if (input === '\u0003') {
        await app.stopApp();
    }
});
