import ansi from './extern/ansi';

export function mount(component: () => void) {
    ansi.clearScreen();
    component();
}
