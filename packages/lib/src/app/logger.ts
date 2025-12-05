import fs from 'fs';
import path from 'path';
import { appendFile } from 'fs/promises';
import type { LoggerOptions } from './define';

const LOG_LEVEL_DEBUG = 0;
const LOG_LEVEL_INFO = 1;
const LOG_LEVEL_WARNING = 2;
const LOG_LEVEL_ERROR = 3;

let cachedTimestampStr: string = '';
let cachedTimestamp = 0;
function timestampStr() {
    const date = new Date();
    const time = date.getTime();
    if (time === cachedTimestamp) {
        return cachedTimestampStr;
    }

    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hour = date.getHours();
    const minute = date.getMinutes();
    const second = date.getSeconds();
    cachedTimestamp = time;
    cachedTimestampStr = `[${year}-${fillZero(month)}-${fillZero(day)} ${fillZero(hour)}:${fillZero(
        minute
    )}:${fillZero(second)}]`;
    return cachedTimestampStr;
}
function fillZero(num: number, len = 2) {
    let str = num.toString();
    while (str.length < len) {
        str = '0' + str;
    }
    return str;
}

export class Logger {
    static #logFileDir: string = '';
    static #logFile: string = '';
    static #logLevel: number = LOG_LEVEL_INFO;
    static #taskQueue: (() => Promise<void> | void)[] = [];
    static #running = false;
    static init(opts: LoggerOptions) {
        this.#logFileDir = opts.logFileDir;
        const logLevel = opts.logLevel;
        const clearLog = opts.clearLog;
        this.#logFile = path.resolve(this.#logFileDir, opts.frontendLogName);
        if (logLevel === 'debug') {
            this.#logLevel = LOG_LEVEL_DEBUG;
        } else if (logLevel === 'info') {
            this.#logLevel = LOG_LEVEL_INFO;
        } else if (logLevel === 'warning') {
            this.#logLevel = LOG_LEVEL_WARNING;
        } else if (logLevel === 'error') {
            this.#logLevel = LOG_LEVEL_ERROR;
        }

        if (!fs.existsSync(this.#logFileDir)) {
            fs.mkdirSync(this.#logFileDir);
        }
        const backendLogPath = path.resolve(
            this.#logFileDir,
            opts.backendLogName || 'term_bed.log'
        );
        if (!fs.existsSync(backendLogPath) || clearLog) {
            fs.writeFileSync(backendLogPath, '');
            fs.writeFileSync(this.#logFile, '');
        }

        this.#running = true;
        const consume = async () => {
            if (!this.#running) {
                return;
            }
            try {
                const task = this.#taskQueue.shift();
                if (task) {
                    await task();
                }
            } catch (e) {
                throw e;
            } finally {
                setImmediate(consume);
            }
        };
        consume();
    }

    static deinit() {
        this.#running = false;
    }

    static logDebug(content: string) {
        if (this.#logLevel === LOG_LEVEL_DEBUG) {
            this.#taskQueue.push(
                async () => await appendFile(this.#logFile, `${timestampStr()} debug: ${content}\n`)
            );
        }
    }

    static logInfo(content: string) {
        if (this.#logLevel <= LOG_LEVEL_INFO) {
            this.#taskQueue.push(
                async () => await appendFile(this.#logFile, `${timestampStr()} info: ${content}\n`)
            );
        }
    }

    static logWarning(content: string) {
        if (this.#logLevel <= LOG_LEVEL_WARNING) {
            this.#taskQueue.push(
                async () =>
                    await appendFile(this.#logFile, `${timestampStr()} warning: ${content}\n`)
            );
        }
    }

    static logError(content: string) {
        if (this.#logLevel <= LOG_LEVEL_ERROR) {
            this.#taskQueue.push(
                async () => await appendFile(this.#logFile, `${timestampStr()} error: ${content}\n`)
            );
        }
    }
}
