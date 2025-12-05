import { createApp, widgets } from 'lib';

const app = createApp({ logLevel: 'debug', clearLog: true, debugMode: true });
const scene = app.createScene({ bgHexRgb: 0x7f60fe });
app.switchScene(scene);
scene
    .mount(widgets.createText('Count: 0', { x: 0, y: 0 }))
    .mount(widgets.createText('Press - / + to change count.', { x: 0, y: 1 }))
    .mount(widgets.createText('Press Ctrl+C to exit.', { x: 0, y: 2 }));

app.start();
