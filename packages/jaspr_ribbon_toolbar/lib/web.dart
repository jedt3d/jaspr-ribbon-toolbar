/// Browser-only entrypoint: the imperative [RibbonCanvasController] and the
/// Canvas 2D [WebCanvasSurface] that drive a `<canvas>` ribbon on the client.
///
/// Import this from a `*.client.dart` entrypoint. It re-exports the VM-pure
/// barrel too, so a client app needs only this one import.
library;

export 'jaspr_ribbon_toolbar.dart';
export 'src/render/menu_overlay.dart';
export 'src/render/ribbon_canvas_controller.dart';
export 'src/render/web_canvas_surface.dart';
