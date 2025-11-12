import { cp } from 'fs/promises';
import path from 'path';
import { suffix } from 'bun:ffi';

const appName = 'tui_app';

const rootDir = path.resolve(import.meta.dir, '..');
const tasks = [
    { from: `/term-native/zig-out/bin/${appName}.${suffix}`, to: `/lib/${appName}.${suffix}` },
    { from: `/term-native/zig-out/bin/${appName}.pdb`, to: `/lib/${appName}.pdb` },
];

for (const task of tasks) {
    await cp(`${rootDir}${task.from}`, `${rootDir}${task.to}`, { recursive: true });
}
