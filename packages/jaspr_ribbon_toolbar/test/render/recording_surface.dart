import 'package:jaspr_ribbon_toolbar/src/render/draw_surface.dart';

/// A deterministic, recording [DrawSurface] for unit tests. Text is measured
/// proportionally to the current font size so layout positions are realistic
/// and reproducible without a browser.
class RecordingSurface with DrawStateMixin implements DrawSurface {
  /// Monotonically-increasing count of primitive draw calls.
  int calls = 0;

  @override
  double measureTextWidth(String text) => text.length * fontSizeState * 0.55;

  @override
  double textHeight() => fontSizeState * 1.3;

  @override
  void fillRect(double x, double y, double w, double h) => calls++;

  @override
  void fillRoundRect(double x, double y, double w, double h, double r) =>
      calls++;

  @override
  void strokeRoundRect(double x, double y, double w, double h, double r) =>
      calls++;

  @override
  void line(double x1, double y1, double x2, double y2) => calls++;

  @override
  void fillText(String text, double x, double y) => calls++;

  @override
  void clear() => calls++;

  @override
  bool drawIcon(
    String iconKey,
    double x,
    double y,
    double size, {
    bool disabled = false,
  }) {
    // Tests have no real icons, so always render the placeholder path.
    return false;
  }
}
