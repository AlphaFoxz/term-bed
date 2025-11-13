import { dlopen, FFIType } from 'bun:ffi';
import { fetchDllPath } from './util';

const lib = dlopen(fetchDllPath(), {
    event_bus_setup: { args: [], returns: FFIType.void },
    event_bus_emit: {
        args: [FFIType.u16, FFIType.ptr, FFIType.uint64_t],
        returns: FFIType.i32,
    },
    event_bus_poll: { args: [], returns: FFIType.ptr },
    event_bus_commit: { args: [], returns: FFIType.void },
    event_bus_stats: { args: [FFIType.ptr], returns: FFIType.void },
}).symbols;

export default lib;
