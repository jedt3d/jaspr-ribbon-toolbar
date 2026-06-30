/// A minimal 2D drawing surface the painter targets.
///
/// Decoupling the renderer from `package:web`'s `CanvasRenderingContext2D`
/// keeps the layout + painter pure-Dart and unit-testable on the VM: tests
/// inject a `RecordingSurface` with a deterministic text measurer, while the
/// browser injects a `WebCanvasSurface` over the real 2D context.
abstract class DrawSurface {
  /// Sets the current text font (size in px, optional bold).
  void setFont({required double size, bool bold = false});

  /// Width of [text] at the currently set font — mirrors Xojo `g.TextWidth`.
  double measureTextWidth(String text);

  /// Approximate text height at the current font — mirrors Xojo `g.TextHeight`.
  double textHeight();

  /// Fills a rectangle with the current fill colour (`g.FillRectangle`).
  void fillRect(double x, double y, double w, double h);

  /// Fills a rounded rectangle with the current fill colour (`g.FillRoundRectangle`).
  void fillRoundRect(double x, double y, double w, double h, double r);

  /// Strokes a rounded rectangle with the current stroke colour (`g.DrawRoundRectangle`).
  void strokeRoundRect(double x, double y, double w, double h, double r);

  /// Draws a line between two points (`g.DrawLine`).
  void line(double x1, double y1, double x2, double y2);

  /// Draws [text] at ([x], [y]) baseline (`g.DrawText`).
  void fillText(String text, double x, double y);

  /// Sets the fill colour (CSS string).
  void setFill(String css);

  /// Sets the stroke colour (CSS string).
  void setStroke(String css);

  /// Sets the line width for subsequent [line] / [strokeRoundRect] calls.
  void setLineWidth(double w);

  /// Draws a registered icon ([iconKey]) into the given square, or returns
  /// `false` so the caller can render a placeholder glyph. When [disabled] is
  /// `true` the implementation should apply a ~40% alpha (Xojo `Transparency`).
  bool drawIcon(
    String iconKey,
    double x,
    double y,
    double size, {
    bool disabled = false,
  });

  /// Clears the whole surface (canvas reset).
  void clear();
}

/// A mixin holding the active fill / stroke / font / line state, so both the
/// recording and web surfaces share the bookkeeping. Apply it with `with` and
/// also `implements DrawSurface`.
mixin DrawStateMixin {
  String _fill = '#000000';
  String _stroke = '#000000';
  double _lineWidth = 1;
  double _fontSize = 11;
  bool _bold = false;

  String get fillState => _fill;
  String get strokeState => _stroke;
  double get lineWidthState => _lineWidth;
  double get fontSizeState => _fontSize;
  bool get boldState => _bold;

  void setFill(String css) => _fill = css;
  void setStroke(String css) => _stroke = css;
  void setLineWidth(double w) => _lineWidth = w;
  void setFont({required double size, bool bold = false}) {
    _fontSize = size;
    _bold = bold;
  }
}
