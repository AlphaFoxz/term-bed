import widgets, { type TextWidgetOptions } from '../extern/widgets';

export default class Text {
    prt: any;
    constructor(options: TextWidgetOptions) {
        widgets.createTextWidget(options);
    }

    private render() {}
}
