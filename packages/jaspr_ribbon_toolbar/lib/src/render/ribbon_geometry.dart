/// Layout constants — a direct port of the `k*` constants in
/// `desktop/XjRibbon.xojo_code`. All values are in CSS pixels.
class RibbonGeometry {
  const RibbonGeometry._();

  static const double tabStripHeight = 24;
  static const double tabPaddingH = 16;
  static const double tabGap = 2;

  static const double contentTop = 26;
  static const double contentPadding = 4;

  static const double groupLabelHeight = 16;
  static const double groupPaddingH = 8;
  static const double groupGap = 8;

  static const double largeButtonWidth = 56;
  static const double largeButtonIconSize = 32;
  static const double itemGap = 4;

  static const double dropdownArrowSize = 6;
  static const double arrowZoneWidth = 20;

  static const double smallButtonHeight = 22;
  static const double smallButtonIconSize = 16;
  static const double smallButtonMinWidth = 60;
  static const double smallButtonTextPadding = 4;
  static const double smallRowGap = 2;

  static const double checkBoxGlyphSize = 13;

  static const double collapseChevronSize = 12;

  /// Font sizes (points) used by the Xojo `DrawText` calls.
  static const double tabFontSize = 13;
  static const double itemFontSize = 11;
  static const double groupLabelFontSize = 10;
  static const double largePlaceholderLetterSize = 18;

  /// Height of the collapsed (tab-strip only) band.
  static const double collapsedHeight = tabStripHeight + 2;
}

/// An axis-aligned rectangle, in CSS pixels.
class RRect {
  const RRect(this.x, this.y, this.w, this.h);

  final double x;
  final double y;
  final double w;
  final double h;

  /// Right edge.
  double get right => x + w;

  /// Bottom edge.
  double get bottom => y + h;

  /// `true` if the point is inside this rectangle (half-open).
  bool containsPoint(double px, double py) =>
      px >= x && px < x + w && py >= y && py < y + h;

  @override
  String toString() => 'RRect($x,$y ${w}x$h)';
}
