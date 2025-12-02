import { type RectWidgetStyleOptions } from '../extern/widgets';
import Text from './Text';

export function createText(text: string, options?: RectWidgetStyleOptions) {
    return new Text(text, options);
}
