/// The ribbon's colour system, an exact port of Xojo's `ResolveColors`.
///
/// Every field maps 1:1 to a `c*` colour in `desktop/XjRibbon.xojo_code`.
/// Colours are stored as ARGB [int]s; the painter converts them to CSS via
/// [RibbonColors.toCssHex] / [RibbonColors.toCssRgba].
class RibbonColors {
  const RibbonColors({
    required this.background,
    required this.contentBackground,
    required this.border,
    required this.tabText,
    required this.tabActiveBackground,
    required this.tabHoverBackground,
    required this.tabAccent,
    required this.itemText,
    required this.itemDisabledText,
    required this.itemHoverBackground,
    required this.itemPressedBackground,
    required this.groupLabelText,
    required this.groupSeparator,
    required this.placeholderIcon,
    required this.placeholderIconDisabled,
    required this.placeholderIconText,
    required this.collapseChevron,
    required this.toggleActiveBackground,
    required this.toggleActiveHoverBackground,
  });

  /// `cBackground` — behind the whole ribbon band.
  final int background;

  /// `cContentBackground` — the group area below the tab strip.
  final int contentBackground;

  /// `cBorder` — hairlines.
  final int border;

  /// `cTabText` — tab label text.
  final int tabText;

  /// `cTabActiveBackground` — active tab fill.
  final int tabActiveBackground;

  /// `cTabHoverBackground` — hovered tab fill.
  final int tabHoverBackground;

  /// `cTabAccent` — active-tab underline / accents (blue).
  final int tabAccent;

  /// `cItemText` — control caption text.
  final int itemText;

  /// `cItemDisabledText` — disabled control caption text.
  final int itemDisabledText;

  /// `cItemHoverBackground` — hovered control fill.
  final int itemHoverBackground;

  /// `cItemPressedBackground` — pressed control fill.
  final int itemPressedBackground;

  /// `cGroupLabelText` — group caption text.
  final int groupLabelText;

  /// `cGroupSeparator` — vertical divider between groups.
  final int groupSeparator;

  /// `cPlaceholderIcon` — placeholder icon fill (no real icon).
  final int placeholderIcon;

  /// `cPlaceholderIconDisabled` — disabled placeholder icon fill.
  final int placeholderIconDisabled;

  /// `cPlaceholderIconText` — letter drawn inside a placeholder icon.
  final int placeholderIconText;

  /// `cCollapseChevron` — collapse/expand chevron.
  final int collapseChevron;

  /// `cToggleActiveBackground` — toggled-on button fill.
  final int toggleActiveBackground;

  /// `cToggleActiveHoverBackground` — toggled-on + hovered button fill.
  final int toggleActiveHoverBackground;

  /// Light-mode palette — exact Xojo `ResolveColors` (else branch).
  static const RibbonColors light = RibbonColors(
    background: 0xFFF5F5F5,
    contentBackground: 0xFFFFFFFF,
    border: 0xFFD2D2D2,
    tabText: 0xFF3C3C3C,
    tabActiveBackground: 0xFFFFFFFF,
    tabHoverBackground: 0xFFE6F0FA,
    tabAccent: 0xFF0078D4,
    itemText: 0xFF3C3C3C,
    itemDisabledText: 0xFFA0A0A0,
    itemHoverBackground: 0xFFDCEFFA,
    itemPressedBackground: 0xFFC8DCF0,
    groupLabelText: 0xFF787878,
    groupSeparator: 0xFFDCDCDC,
    placeholderIcon: 0xFF0078D4,
    placeholderIconDisabled: 0xFFB4B4B4,
    placeholderIconText: 0xFFFFFFFF,
    collapseChevron: 0xFF787878,
    toggleActiveBackground: 0xFFC8DCF0,
    toggleActiveHoverBackground: 0xFFB9D2EB,
  );

  /// Dark-mode palette — exact Xojo `ResolveColors` (If branch).
  static const RibbonColors dark = RibbonColors(
    background: 0xFF282828,
    contentBackground: 0xFF323232,
    border: 0xFF464646,
    tabText: 0xFFDCDCDC,
    tabActiveBackground: 0xFF323232,
    tabHoverBackground: 0xFF3C4650,
    tabAccent: 0xFF3C96E6,
    itemText: 0xFFDCDCDC,
    itemDisabledText: 0xFF646464,
    itemHoverBackground: 0xFF46505F,
    itemPressedBackground: 0xFF37465A,
    groupLabelText: 0xFF969696,
    groupSeparator: 0xFF464646,
    placeholderIcon: 0xFF3C96E6,
    placeholderIconDisabled: 0xFF505050,
    placeholderIconText: 0xFFFFFFFF,
    collapseChevron: 0xFF969696,
    toggleActiveBackground: 0xFF37465A,
    toggleActiveHoverBackground: 0xFF415064,
  );

  /// Resolves the palette for the given mode (mirrors `ResolveColors`).
  factory RibbonColors.resolve({required bool isDarkMode}) =>
      isDarkMode ? RibbonColors.dark : RibbonColors.light;

  /// Formats [argb] as a CSS `#RRGGBB` string.
  static String toCssHex(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  /// Formats [argb] as a CSS `rgba()` string using its alpha channel.
  static String toCssRgba(int argb) {
    final a = ((argb >> 24) & 0xFF) / 255.0;
    return _rgba(argb, a);
  }

  /// Formats the RGB channels of [argb] as a CSS `rgba()` string with a custom
  /// [alpha] override (0.0–1.0). Used for the contextual-tab accent wash.
  static String toCssRgbaWith(int argb, double alpha) => _rgba(argb, alpha);

  static String _rgba(int argb, double a) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return 'rgba($r, $g, $b, ${a.toStringAsFixed(3)})';
  }

  @override
  String toString() =>
      'RibbonColors(bg=${toCssHex(background)}, accent=${toCssHex(tabAccent)})';
}
