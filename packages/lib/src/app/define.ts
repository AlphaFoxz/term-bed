import type { LogLevel } from '../extern/app';

export interface Disposable {
    dispose(): void | Promise<void>;
    [Symbol.dispose](): void;
    [Symbol.asyncDispose](): void;
}

export interface WidgetLike extends Disposable {
    readonly id: number;
}

export type LoggerOptions = {
    logFileDir: string;
    logLevel: LogLevel;
    clearLog: boolean;
    frontendLogName: string;
    backendLogName: string;
};
