import { createApp, widgets } from './';

const app = createApp({ logLevel: 'debug', clearLog: true });
const scene = app.createScene();
scene.mount(widgets.createText('Count: 0'));
scene.mount(widgets.createText('Press - / + to change count.'));
scene.mount(widgets.createText('Press Ctrl+C to exit.'));
app.switchScene(scene);
app.start();

let count = 0;
process.stdin.on('data', async (data) => {
    const input = data.toString().trim();
    if (input === '-') count -= 1;
    if (input === '+') count += 1;
    if (input === '\u0003') {
        await app.stop();
    }
});
