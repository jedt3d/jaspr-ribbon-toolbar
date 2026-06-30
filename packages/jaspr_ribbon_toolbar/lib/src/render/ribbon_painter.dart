import 'dart:math' as math;

import '../model/item_type.dart';
import '../theme/ribbon_colors.dart';
import 'draw_surface.dart';
import 'ribbon_geometry.dart';
import 'ribbon_layout.dart';

/// Interaction state for a single paint pass. Tracked by the client component
/// and mutated on pointer events; immutable value object otherwise.
class RibbonPaintState {
  const RibbonPaintState({
    this.activeTabIndex = 0,
    this.collapsed = false,
    this.hoveredTabIndex = -1,
    this.hoveredItemTag,
    this.pressedItemTag,
    this.pressedOnArrow = false,
  });

  final int activeTabIndex;
  final bool collapsed;
  final int hoveredTabIndex;
  final String? hoveredItemTag;
  final String? pressedItemTag;
  final bool pressedOnArrow;

  RibbonPaintState copyWith({
    int? activeTabIndex,
    bool? collapsed,
    int? hoveredTabIndex,
    Object? hoveredItemTag = _sentinel,
    Object? pressedItemTag = _sentinel,
    bool? pressedOnArrow,
  }) {
    return RibbonPaintState(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      collapsed: collapsed ?? this.collapsed,
      hoveredTabIndex: hoveredTabIndex ?? this.hoveredTabIndex,
      hoveredItemTag: identical(hoveredItemTag, _sentinel)
          ? this.hoveredItemTag
          : hoveredItemTag as String?,
      pressedItemTag: identical(pressedItemTag, _sentinel)
          ? this.pressedItemTag
          : pressedItemTag as String?,
      pressedOnArrow: pressedOnArrow ?? this.pressedOnArrow,
    );
  }
}

const Object _sentinel = Object();

/// Paints a [RibbonLayout] onto a [DrawSurface], porting the `Draw*` methods of
/// `desktop/XjRibbon.xojo_code`.
class RibbonPainter {
  const RibbonPainter({required this.colors});

  final RibbonColors colors;

  /// Full paint, mirroring the Xojo `Paint` event ordering.
  void paint(DrawSurface s, RibbonLayout layout, RibbonPaintState state) {
    s.clear();
    _drawBackground(s, layout);
    _drawTabStrip(s, layout, state);
    if (!state.collapsed) {
      _drawContentArea(s, layout);
      _drawGroups(s, layout, state);
    }
    _drawCollapseChevron(s, layout, state);
  }

  void _drawBackground(DrawSurface s, RibbonLayout layout) {
    s.setFill(RibbonColors.toCssHex(colors.background));
    s.fillRect(0, 0, layout.width, layout.height);
    s.setFill(RibbonColors.toCssHex(colors.border));
    s.fillRect(0, layout.height - 1, layout.width, 1);
  }

  void _drawTabStrip(
    DrawSurface s,
    RibbonLayout layout,
    RibbonPaintState state,
  ) {
    for (var i = 0; i < layout.tabs.length; i++) {
      final t = layout.tabs[i];
      final rect = t.rect;
      final isActive = i == state.activeTabIndex;
      final isHovered = i == state.hoveredTabIndex;
      // Contextual tab accent wash + top bar (ports Xojo `IsContextual And IsContextVisible`).
      if (t.tab.isContextual && t.tab.accentColor != null) {
        s.setFill(RibbonColors.toCssRgbaWith(t.tab.accentColor!, 0.18));
        s.fillRect(rect.x, rect.y, rect.w, rect.h);
        s.setFill(RibbonColors.toCssHex(t.tab.accentColor!));
        s.fillRect(rect.x, 0, rect.w, 3);
      }
      if (isActive) {
        s.setFill(RibbonColors.toCssHex(colors.tabActiveBackground));
        s.fillRect(rect.x, rect.y, rect.w, rect.h);
        s.setFill(RibbonColors.toCssHex(t.tab.accentColor ?? colors.tabAccent));
        s.fillRect(rect.x, 0, rect.w, 2);
      } else if (isHovered) {
        s.setFill(RibbonColors.toCssHex(colors.tabHoverBackground));
        s.fillRect(rect.x, rect.y, rect.w, rect.h);
      }
      s.setFill(RibbonColors.toCssHex(colors.tabText));
      s.setFont(size: RibbonGeometry.tabFontSize);
      final textW = s.measureTextWidth(t.tab.caption);
      final textX = rect.x + (rect.w - textW) / 2;
      final textY = rect.y + (rect.h + s.textHeight()) / 2 - 2;
      s.fillText(t.tab.caption, textX, textY);
    }
    s.setFill(RibbonColors.toCssHex(colors.border));
    s.fillRect(0, RibbonGeometry.tabStripHeight, layout.width, 1);
  }

  void _drawContentArea(DrawSurface s, RibbonLayout layout) {
    s.setFill(RibbonColors.toCssHex(colors.contentBackground));
    s.fillRect(
      0,
      RibbonGeometry.contentTop,
      layout.width,
      layout.height - RibbonGeometry.contentTop - 1,
    );
  }

  void _drawGroups(DrawSurface s, RibbonLayout layout, RibbonPaintState state) {
    for (var gi = 0; gi < layout.groups.length; gi++) {
      final g = layout.groups[gi];
      for (final laid in g.items) {
        final item = laid.item;
        switch (item.itemType) {
          case RibbonItemType.small:
            _drawSmallButton(s, laid, state);
            break;
          case RibbonItemType.dropdown:
            _drawDropdownButton(s, laid, state);
            break;
          case RibbonItemType.checkBox:
            _drawCheckBoxItem(s, laid, state);
            break;
          case RibbonItemType.separator:
            break;
          case RibbonItemType.large:
            _drawLargeButton(s, laid, state);
            break;
        }
      }
      // Group label.
      s.setFill(RibbonColors.toCssHex(colors.groupLabelText));
      s.setFont(size: RibbonGeometry.groupLabelFontSize);
      final labelW = s.measureTextWidth(g.group.caption);
      s.fillText(
        g.group.caption,
        g.rect.x + (g.rect.w - labelW) / 2,
        g.rect.y + g.rect.h - 3,
      );
      // Group separator (between groups).
      if (gi < layout.groups.length - 1) {
        s.setFill(RibbonColors.toCssHex(colors.groupSeparator));
        s.fillRect(
          g.rect.right + RibbonGeometry.groupGap / 2,
          g.rect.y + 2,
          1,
          g.rect.h - RibbonGeometry.groupLabelHeight - 4,
        );
      }
    }
  }

  bool _isHovered(LaidItem laid, RibbonPaintState s) =>
      laid.item.tag == s.hoveredItemTag;
  bool _isPressed(LaidItem laid, RibbonPaintState s) =>
      laid.item.tag == s.pressedItemTag;

  void _drawLargeButton(DrawSurface s, LaidItem laid, RibbonPaintState state) {
    final item = laid.item;
    final r = laid.rect;
    final hovered = _isHovered(laid, state);
    final pressed = _isPressed(laid, state);

    if (pressed) {
      s.setFill(RibbonColors.toCssHex(colors.itemPressedBackground));
      s.fillRoundRect(r.x, r.y, r.w, r.h, 4);
    } else if (item.isToggle && item.isToggleActive) {
      s.setFill(
        RibbonColors.toCssHex(
          hovered
              ? colors.toggleActiveHoverBackground
              : colors.toggleActiveBackground,
        ),
      );
      s.fillRoundRect(r.x, r.y, r.w, r.h, 4);
      s.setStroke(RibbonColors.toCssHex(colors.border));
      s.setLineWidth(1);
      s.strokeRoundRect(r.x + 0.5, r.y + 0.5, r.w - 1, r.h - 1, 4);
    } else if (hovered) {
      s.setFill(RibbonColors.toCssHex(colors.itemHoverBackground));
      s.fillRoundRect(r.x, r.y, r.w, r.h, 4);
    }

    final iconSize = RibbonGeometry.largeButtonIconSize;
    final iconX = r.x + (r.w - iconSize) / 2;
    final iconY = r.y + 6;
    final hasIcon =
        item.iconKey != null &&
        s.drawIcon(
          item.iconKey!,
          iconX,
          iconY,
          iconSize,
          disabled: !item.isEnabled,
        );
    if (!hasIcon) {
      s.setFill(
        RibbonColors.toCssHex(
          item.isEnabled
              ? colors.placeholderIcon
              : colors.placeholderIconDisabled,
        ),
      );
      s.fillRoundRect(iconX, iconY, iconSize, iconSize, 4);
      s.setFill(RibbonColors.toCssHex(colors.placeholderIconText));
      s.setFont(size: RibbonGeometry.largePlaceholderLetterSize, bold: true);
      final letter = item.caption.isEmpty ? '?' : item.caption.substring(0, 1);
      final letterW = s.measureTextWidth(letter);
      s.fillText(
        letter,
        iconX + (iconSize - letterW) / 2,
        iconY + iconSize / 2 + s.textHeight() / 2 - 3,
      );
    }

    s.setFill(
      RibbonColors.toCssHex(
        item.isEnabled ? colors.itemText : colors.itemDisabledText,
      ),
    );
    s.setFont(size: RibbonGeometry.itemFontSize);
    final drawBodyW = item.isSplitButton
        ? r.w - RibbonGeometry.arrowZoneWidth
        : r.w;
    final belowY = iconY + iconSize;
    final belowH = r.h - (belowY - r.y);
    final th = s.textHeight();
    final lines = item.caption.split('\n');
    if (lines.length > 1) {
      const lineGap = 1.0;
      final blockH = th * 2 + lineGap;
      final blockTop = belowY + math.max(0, (belowH - blockH) / 2);
      for (var li = 0; li < 2 && li < lines.length; li++) {
        final lw = s.measureTextWidth(lines[li]);
        final lx = item.isSplitButton
            ? r.x + drawBodyW - lw - 4
            : r.x + (drawBodyW - lw) / 2;
        s.fillText(lines[li], lx, blockTop + th + li * (th + lineGap));
      }
    } else {
      final textW = s.measureTextWidth(item.caption);
      final textX = item.isSplitButton
          ? r.x + drawBodyW - textW - 4
          : r.x + (drawBodyW - textW) / 2;
      s.fillText(item.caption, textX, belowY + (belowH - th) / 2 + th);
    }
  }

  void _drawSmallButton(DrawSurface s, LaidItem laid, RibbonPaintState state) {
    final item = laid.item;
    final r = laid.rect;
    final hovered = _isHovered(laid, state);
    final pressed = _isPressed(laid, state);

    if (pressed) {
      s.setFill(RibbonColors.toCssHex(colors.itemPressedBackground));
      s.fillRoundRect(r.x, r.y, r.w, r.h, 3);
    } else if (item.isToggle && item.isToggleActive) {
      s.setFill(
        RibbonColors.toCssHex(
          hovered
              ? colors.toggleActiveHoverBackground
              : colors.toggleActiveBackground,
        ),
      );
      s.fillRoundRect(r.x, r.y, r.w, r.h, 3);
      s.setStroke(RibbonColors.toCssHex(colors.border));
      s.setLineWidth(1);
      s.strokeRoundRect(r.x + 0.5, r.y + 0.5, r.w - 1, r.h - 1, 3);
    } else if (hovered) {
      s.setFill(RibbonColors.toCssHex(colors.itemHoverBackground));
      s.fillRoundRect(r.x, r.y, r.w, r.h, 3);
    }

    final iconX = r.x + 3;
    final iconY = r.y + (r.h - RibbonGeometry.smallButtonIconSize) / 2;
    final hasIcon =
        item.iconKey != null &&
        s.drawIcon(
          item.iconKey!,
          iconX,
          iconY,
          RibbonGeometry.smallButtonIconSize,
          disabled: !item.isEnabled,
        );
    if (!hasIcon) {
      s.setFill(
        RibbonColors.toCssHex(
          item.isEnabled
              ? colors.placeholderIcon
              : colors.placeholderIconDisabled,
        ),
      );
      s.fillRoundRect(
        iconX,
        iconY,
        RibbonGeometry.smallButtonIconSize,
        RibbonGeometry.smallButtonIconSize,
        2,
      );
    }

    s.setFill(
      RibbonColors.toCssHex(
        item.isEnabled ? colors.itemText : colors.itemDisabledText,
      ),
    );
    s.setFont(size: RibbonGeometry.itemFontSize);
    s.fillText(
      item.caption,
      iconX +
          RibbonGeometry.smallButtonIconSize +
          RibbonGeometry.smallButtonTextPadding,
      r.y + (r.h + s.textHeight()) / 2 - 1,
    );
  }

  void _drawDropdownButton(
    DrawSurface s,
    LaidItem laid,
    RibbonPaintState state,
  ) {
    _drawLargeButton(s, laid, state);
    final item = laid.item;
    final r = laid.rect;
    final arrowW = RibbonGeometry.dropdownArrowSize;
    s.setStroke(
      RibbonColors.toCssHex(
        item.isEnabled ? colors.itemText : colors.itemDisabledText,
      ),
    );
    s.setLineWidth(1.5);

    double arrowX;
    if (item.isSplitButton) {
      final sepX = r.right - RibbonGeometry.arrowZoneWidth;
      s.setFill(RibbonColors.toCssHex(colors.border));
      s.fillRect(sepX, r.y + 4, 1, r.h - 8);
      arrowX = sepX + (RibbonGeometry.arrowZoneWidth - arrowW) / 2;
    } else {
      arrowX = r.x + (r.w - arrowW) / 2;
    }
    final arrowY = r.bottom - 6;
    final midX = arrowX + arrowW / 2;
    s.line(arrowX, arrowY, midX, arrowY + arrowW / 2);
    s.line(midX, arrowY + arrowW / 2, arrowX + arrowW, arrowY);
    s.setLineWidth(1);
  }

  void _drawCheckBoxItem(DrawSurface s, LaidItem laid, RibbonPaintState state) {
    final item = laid.item;
    final r = laid.rect;
    final hovered = _isHovered(laid, state);
    final pressed = _isPressed(laid, state);

    if (pressed) {
      s.setFill(RibbonColors.toCssHex(colors.itemPressedBackground));
      s.fillRoundRect(r.x, r.y, r.w, r.h, 3);
    } else if (hovered) {
      s.setFill(RibbonColors.toCssHex(colors.itemHoverBackground));
      s.fillRoundRect(r.x, r.y, r.w, r.h, 3);
    }

    final glyphSize = RibbonGeometry.checkBoxGlyphSize;
    final glyphX = r.x + 2;
    final glyphY = r.y + (r.h - glyphSize) / 2;

    if (item.isToggleActive) {
      s.setFill(RibbonColors.toCssHex(colors.tabAccent));
      s.fillRoundRect(glyphX, glyphY, glyphSize, glyphSize, 2);
      s.setStroke('#ffffff');
      s.setLineWidth(1.5);
      s.line(glyphX + 2, glyphY + 6, glyphX + 5, glyphY + 9);
      s.line(glyphX + 5, glyphY + 9, glyphX + 11, glyphY + 3);
      s.setLineWidth(1);
    } else {
      s.setFill(RibbonColors.toCssHex(colors.contentBackground));
      s.fillRoundRect(glyphX, glyphY, glyphSize, glyphSize, 2);
      s.setStroke(RibbonColors.toCssHex(colors.border));
      s.setLineWidth(1);
      s.strokeRoundRect(glyphX, glyphY, glyphSize, glyphSize, 2);
    }

    s.setFill(
      RibbonColors.toCssHex(
        item.isEnabled ? colors.itemText : colors.itemDisabledText,
      ),
    );
    s.setFont(size: RibbonGeometry.itemFontSize);
    final textX = glyphX + glyphSize + RibbonGeometry.smallButtonTextPadding;
    s.fillText(item.caption, textX, r.y + (r.h + s.textHeight()) / 2 - 1);
  }

  void _drawCollapseChevron(
    DrawSurface s,
    RibbonLayout layout,
    RibbonPaintState state,
  ) {
    final c = layout.collapseChevron;
    if (c == null) return;
    final midX = c.x + c.w / 2;
    s.setStroke(RibbonColors.toCssHex(colors.collapseChevron));
    s.setLineWidth(1.5);
    if (state.collapsed) {
      final topY = c.y + 2;
      s.line(c.x, topY, midX, topY + c.w / 2);
      s.line(midX, topY + c.w / 2, c.right, topY);
    } else {
      final botY = c.bottom - 2;
      s.line(c.x, botY, midX, botY - c.w / 2);
      s.line(midX, botY - c.w / 2, c.right, botY);
    }
    s.setLineWidth(1);
  }
}
