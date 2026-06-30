import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'draw_surface.dart';

/// A [DrawSurface] backed by a browser [web.CanvasRenderingContext2D].
///
/// All Xojo `Graphics` calls map onto Canvas 2D here (see
/// `docs/porting-from-xojo.md` for the translation table). The surface owns
/// only the drawing context — geometry is decided by the layout + painter.
class WebCanvasSurface with DrawStateMixin implements DrawSurface {
  WebCanvasSurface(this.ctx);

  final web.CanvasRenderingContext2D ctx;

  String get _fontSpec {
    final weight = boldState ? 'bold ' : '';
    return '$weight${fontSizeState}px "Segoe UI", system-ui, sans-serif';
  }

  @override
  double measureTextWidth(String text) {
    ctx.font = _fontSpec;
    return ctx.measureText(text).width.toDouble();
  }

  @override
  double textHeight() => fontSizeState * 1.3;

  void _applyFill() => ctx.fillStyle = fillState.toJS;
  void _applyStroke() => ctx.strokeStyle = strokeState.toJS;
  void _applyFont() => ctx.font = _fontSpec;
  void _applyLineWidth() => ctx.lineWidth = lineWidthState;

  @override
  void fillRect(double x, double y, double w, double h) {
    _applyFill();
    ctx.fillRect(x, y, w, h);
  }

  @override
  void fillRoundRect(double x, double y, double w, double h, double r) {
    _pathRoundRect(x, y, w, h, r);
    _applyFill();
    ctx.fill();
  }

  @override
  void strokeRoundRect(double x, double y, double w, double h, double r) {
    _pathRoundRect(x, y, w, h, r);
    _applyStroke();
    _applyLineWidth();
    ctx.stroke();
  }

  void _pathRoundRect(double x, double y, double w, double h, double r) {
    final cap = r > w / 2 ? w / 2 : r;
    final rr = cap > h / 2 ? h / 2 : cap;
    ctx.beginPath();
    ctx.moveTo(x + rr, y);
    ctx.arcTo(x + w, y, x + w, y + h, rr);
    ctx.arcTo(x + w, y + h, x, y + h, rr);
    ctx.arcTo(x, y + h, x, y, rr);
    ctx.arcTo(x, y, x + w, y, rr);
    ctx.closePath();
  }

  @override
  void line(double x1, double y1, double x2, double y2) {
    _applyStroke();
    _applyLineWidth();
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
  }

  @override
  void fillText(String text, double x, double y) {
    _applyFill();
    _applyFont();
    ctx.fillText(text, x, y);
  }

  @override
  bool drawIcon(
    String iconKey,
    double x,
    double y,
    double size, {
    bool disabled = false,
  }) {
    final img = _IconImageCache.get(iconKey);
    if (img == null || !_IconImageCache.isLoaded(iconKey)) return false;
    if (disabled) ctx.globalAlpha = 0.4;
    ctx.drawImage(img, x, y, size, size);
    if (disabled) ctx.globalAlpha = 1.0;
    return true;
  }

  @override
  void clear() {
    final c = ctx.canvas;
    ctx.clearRect(0, 0, c.width.toDouble(), c.height.toDouble());
  }
}

/// A tiny cache of decoded icon images, populated by [RibbonCanvasController]
/// during its preload pass. Keys are the `RibbonItem.iconKey` values.
class _IconImageCache {
  static final Map<String, web.HTMLImageElement> _imgs = {};
  static final Set<String> _loaded = {};

  static void register(String key, String src, void Function() onLoaded) {
    if (_imgs.containsKey(key)) return;
    final img = web.HTMLImageElement();
    _imgs[key] = img;
    img.onLoad.listen((_) {
      _loaded.add(key);
      onLoaded();
    });
    img.src = src;
  }

  static web.HTMLImageElement? get(String key) => _imgs[key];
  static bool isLoaded(String key) => _loaded.contains(key);
  static void reset() {
    _imgs.clear();
    _loaded.clear();
  }
}

/// Allows the controller to seed the icon cache. Exposed for the controller.
void registerIconImage(String key, String src, void Function() onLoaded) =>
    _IconImageCache.register(key, src, onLoaded);

void resetIconImages() => _IconImageCache.reset();
