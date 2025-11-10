const TuiApp = @import("./core/tui_app.zig").TuiApp;

pub fn forceRender(app_ptr: *TuiApp) void {
    const width = app_ptr.context.screen_rect.cols;
    const height = app_ptr.context.screen_rect.rows;
    app_ptr.context.screen_buffer.resize(width, height);
    app_ptr.forceRender();
}
