# Readme

## zig naming rules

### functions

- Use camelCase
- **A APPLYING FUNCTION MUST BE PAIRED TO A RELEASING FUNCTION**. Such as:
  - `create`Object() and `destroy`Object()
  - `init`Source() and `deinit`Source()
  - `open`Streaming() and `close`Streaming()
  - `connect`() and `disconnect`()
  - `lock`() and `unlock`()
  - `alloc`One() and `free`Arr() / `destroy`One()
  - `register`() and `unregister`()
  - `load`() and `unload`()
  - `start`() and `stop`()
  - `enter`() and `exit`()

### variables

- Naming local variables using snake_case
- Naming global variables using SCREAMING_SNAKE_CASE
- Naming function using camelCase
- Naming struct using PascalCase

## zig atomic

### .unordered

### .monotonic

### .acquire

### .release

### .acq_rel

### .seq_cst
