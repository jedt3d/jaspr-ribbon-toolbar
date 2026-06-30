/// An MS Office–style ribbon toolbar component for Jaspr web apps.
///
/// Renders to an HTML5 `<canvas>` (the Jaspr counterpart of Xojo's
/// `DesktopCanvas` / `WebCanvas`). This barrel is **VM-pure**: it exposes the
/// component, the data model, and the layout/painter, all of which compile
/// without a browser.
///
/// For the imperative browser driver (`RibbonCanvasController`) and the Canvas
/// 2D surface, import `package:jaspr_ribbon_toolbar/web.dart` instead.
library;

export 'model.dart';
export 'src/components/ribbon_toolbar.dart';
export 'src/render/draw_surface.dart';
export 'src/render/ribbon_geometry.dart';
export 'src/render/ribbon_layout.dart';
export 'src/render/ribbon_painter.dart';
