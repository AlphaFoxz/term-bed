import { type TextWidgetStyleOptions } from '../extern/widgets';
import Text from './Text';

export function createText(text: string, options?: TextWidgetStyleOptions) {
    return new Text(options || { width: 20, height: 1, text });
}
