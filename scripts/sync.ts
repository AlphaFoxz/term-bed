import { cp } from 'fs/promises';
import path from 'path';
import { suffix } from 'bun:ffi';

const appName = 'tui_app';

const rootDir = path.resolve(import.meta.dir, '..');
const tasks = [
    { from: `/lib/${appName}.${suffix}`, to: `/dist/${appName}.${suffix}` },
    { from: `/lib/${appName}.pdb`, to: `/dist/${appName}.pdb` },
];

for (const task of tasks) {
    await cp(`${rootDir}${task.from}`, `${rootDir}${task.to}`, { recursive: true });
}
