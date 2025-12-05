import { type RectWidgetInfoOptions } from '../extern/widgets';
import Text from './Text';

export function createText(text: string, options?: Partial<RectWidgetInfoOptions>) {
    return new Text(text, options);
}
