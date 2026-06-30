import '../model/item_type.dart';
import '../model/ribbon_definition.dart';
import '../model/ribbon_group.dart';
import '../model/ribbon_item.dart';
import '../model/ribbon_tab.dart';
import 'draw_surface.dart';
import 'ribbon_geometry.dart';

/// The laid-out position of a single item, including the split-button body /
/// arrow sub-rectangles used for hit-testing.
class LaidItem {
  const LaidItem(this.item, this.rect, {this.bodyRect, this.arrowRect});

  final RibbonItem item;
  final RRect rect;

  /// For split buttons, the clickable body area (excludes the arrow zone).
  final RRect? bodyRect;

  /// For split buttons, the arrow (menu-opener) area.
  final RRect? arrowRect;

  /// `true` if ([px], [py]) lands on this item's interactive area.
  bool hit(double px, double py) {
    if (item.isSeparator) return false;
    if (!rect.containsPoint(px, py)) return false;
    return true;
  }

  /// `true` if ([px], [py]) lands specifically on a split button's arrow area.
  bool hitArrow(double px, double py) =>
      arrowRect?.containsPoint(px, py) ?? false;
}

/// A laid-out group with its bounds and child items.
class LaidGroup {
  const LaidGroup(this.group, this.rect, this.items);

  final RibbonGroup group;
  final RRect rect;
  final List<LaidItem> items;
}

/// A laid-out tab strip entry.
class LaidTab {
  const LaidTab(this.tab, this.rect);
  final RibbonTab tab;
  final RRect rect;
}

/// The complete result of a layout pass: enough geometry for both hit-testing
/// and painting.
class RibbonLayout {
  const RibbonLayout({
    required this.width,
    required this.height,
    required this.tabs,
    required this.groups,
    required this.collapseChevron,
    required this.collapsed,
  });

  final double width;
  final double height;
  final List<LaidTab> tabs;
  final List<LaidGroup> groups;
  final RRect? collapseChevron;
  final bool collapsed;

  /// Tab under the point, or `null`.
  LaidTab? hitTab(double px, double py) {
    for (final t in tabs) {
      if (t.rect.containsPoint(px, py)) return t;
    }
    return null;
  }

  /// Item under the point, or `null`.
  LaidItem? hitItem(double px, double py) {
    for (final g in groups) {
      for (final i in g.items) {
        if (i.hit(px, py)) return i;
      }
    }
    return null;
  }

  /// `true` if the point is on the collapse chevron.
  bool hitChevron(double px, double py) =>
      collapseChevron?.containsPoint(px, py) ?? false;

  /// Computes a layout for [definition] using [surface] for text measurement.
  /// Ports `LayoutTabs` from `desktop/XjRibbon.xojo_code` line-for-line.
  static RibbonLayout compute({
    required RibbonDefinition definition,
    required DrawSurface surface,
    required double width,
    required double height,
    required int activeTabIndex,
    required bool collapsed,
    Set<String> visibleContextGroups = const {},
  }) {
    final tabs = <LaidTab>[];
    var tabX = RibbonGeometry.tabPaddingH;
    for (final tab in definition.tabs) {
      if (tab.isContextual &&
          !visibleContextGroups.contains(tab.contextGroup)) {
        continue;
      }
      surface.setFont(size: RibbonGeometry.tabFontSize);
      final textW = surface.measureTextWidth(tab.caption);
      tabs.add(
        LaidTab(
          tab,
          RRect(
            tabX,
            0,
            textW + RibbonGeometry.tabPaddingH * 2,
            RibbonGeometry.tabStripHeight,
          ),
        ),
      );
      tabX += textW + RibbonGeometry.tabPaddingH * 2 + RibbonGeometry.tabGap;
    }

    final chevron = RRect(
      width - RibbonGeometry.collapseChevronSize - 8,
      (RibbonGeometry.tabStripHeight - RibbonGeometry.collapseChevronSize) / 2,
      RibbonGeometry.collapseChevronSize,
      RibbonGeometry.collapseChevronSize,
    );

    if (collapsed ||
        activeTabIndex < 0 ||
        activeTabIndex >= definition.tabs.length) {
      return RibbonLayout(
        width: width,
        height: collapsed ? RibbonGeometry.collapsedHeight : height,
        tabs: tabs,
        groups: const [],
        collapseChevron: chevron,
        collapsed: collapsed,
      );
    }

    final activeTab = definition.tabs[activeTabIndex];
    final contentY = RibbonGeometry.contentTop + RibbonGeometry.contentPadding;
    final contentH =
        height - RibbonGeometry.contentTop - RibbonGeometry.contentPadding * 2;
    final itemAreaH = contentH - RibbonGeometry.groupLabelHeight;

    final groups = <LaidGroup>[];
    var groupX = RibbonGeometry.groupPaddingH;

    for (final group in activeTab.groups) {
      var itemX = groupX + RibbonGeometry.groupPaddingH;
      final laidItems = <LaidItem>[];
      var idx = 0;
      while (idx < group.items.length) {
        final item = group.items[idx];

        if (item.itemType == RibbonItemType.small) {
          // Batch up to three consecutive small buttons into one column.
          final batch = <RibbonItem>[];
          var maxTextW = 0.0;
          while (idx < group.items.length &&
              group.items[idx].itemType == RibbonItemType.small &&
              batch.length < 3) {
            final it = group.items[idx];
            surface.setFont(size: RibbonGeometry.itemFontSize);
            final tw = surface.measureTextWidth(it.caption);
            if (tw > maxTextW) maxTextW = tw;
            batch.add(it);
            idx++;
          }
          var colWidth =
              RibbonGeometry.smallButtonIconSize +
              RibbonGeometry.smallButtonTextPadding +
              maxTextW +
              RibbonGeometry.smallButtonTextPadding * 2;
          if (colWidth < RibbonGeometry.smallButtonMinWidth)
            colWidth = RibbonGeometry.smallButtonMinWidth;
          final totalRowH =
              batch.length * RibbonGeometry.smallButtonHeight +
              (batch.length - 1) * RibbonGeometry.smallRowGap;
          final startY = contentY + (itemAreaH - totalRowH) / 2;
          for (var row = 0; row < batch.length; row++) {
            laidItems.add(
              LaidItem(
                batch[row],
                RRect(
                  itemX,
                  startY +
                      row *
                          (RibbonGeometry.smallButtonHeight +
                              RibbonGeometry.smallRowGap),
                  colWidth,
                  RibbonGeometry.smallButtonHeight,
                ),
              ),
            );
          }
          itemX += colWidth + RibbonGeometry.itemGap;
        } else if (item.itemType == RibbonItemType.checkBox) {
          // Batch up to three consecutive checkboxes into one column.
          final batch = <RibbonItem>[];
          var maxTextW = 0.0;
          while (idx < group.items.length &&
              group.items[idx].itemType == RibbonItemType.checkBox &&
              batch.length < 3) {
            final it = group.items[idx];
            surface.setFont(size: RibbonGeometry.itemFontSize);
            final tw = surface.measureTextWidth(it.caption);
            if (tw > maxTextW) maxTextW = tw;
            batch.add(it);
            idx++;
          }
          var colWidth =
              RibbonGeometry.checkBoxGlyphSize +
              RibbonGeometry.smallButtonTextPadding +
              maxTextW +
              RibbonGeometry.smallButtonTextPadding * 2;
          if (colWidth < RibbonGeometry.smallButtonMinWidth)
            colWidth = RibbonGeometry.smallButtonMinWidth;
          final totalRowH =
              batch.length * RibbonGeometry.smallButtonHeight +
              (batch.length - 1) * RibbonGeometry.smallRowGap;
          final startY = contentY + (itemAreaH - totalRowH) / 2;
          for (var row = 0; row < batch.length; row++) {
            laidItems.add(
              LaidItem(
                batch[row],
                RRect(
                  itemX,
                  startY +
                      row *
                          (RibbonGeometry.smallButtonHeight +
                              RibbonGeometry.smallRowGap),
                  colWidth,
                  RibbonGeometry.smallButtonHeight,
                ),
              ),
            );
          }
          itemX += colWidth + RibbonGeometry.itemGap;
        } else if (item.itemType == RibbonItemType.separator) {
          // Separator: visual column gap, no bounds, no draw.
          itemX += RibbonGeometry.itemGap;
          idx++;
        } else {
          // Large / dropdown / toggle — large-format button.
          surface.setFont(size: RibbonGeometry.itemFontSize);
          var maxCapW = 0.0;
          for (final line in item.caption.split('\n')) {
            final lw = surface.measureTextWidth(line);
            if (lw > maxCapW) maxCapW = lw;
          }
          var btnW = RibbonGeometry.largeButtonWidth;
          if (maxCapW + 16 > btnW) btnW = maxCapW + 16;
          if (item.isSplitButton) btnW += RibbonGeometry.arrowZoneWidth;
          final rect = RRect(itemX, contentY, btnW, itemAreaH);
          LaidItem laid;
          if (item.isSplitButton) {
            final body = RRect(
              itemX,
              contentY,
              btnW - RibbonGeometry.arrowZoneWidth,
              itemAreaH,
            );
            final arrow = RRect(
              itemX + btnW - RibbonGeometry.arrowZoneWidth,
              contentY,
              RibbonGeometry.arrowZoneWidth,
              itemAreaH,
            );
            laid = LaidItem(item, rect, bodyRect: body, arrowRect: arrow);
          } else {
            laid = LaidItem(item, rect);
          }
          laidItems.add(laid);
          itemX += btnW + RibbonGeometry.itemGap;
          idx++;
        }
      }

      var groupInnerW = itemX - groupX - RibbonGeometry.groupPaddingH;
      if (group.items.isNotEmpty) groupInnerW -= RibbonGeometry.itemGap;
      groupInnerW += RibbonGeometry.groupPaddingH;
      final labelW =
          surface.measureTextWidth(group.caption) +
          RibbonGeometry.groupPaddingH * 2;
      final groupW = (groupInnerW + RibbonGeometry.groupPaddingH).clamp(
        labelW,
        double.infinity,
      );
      groups.add(
        LaidGroup(group, RRect(groupX, contentY, groupW, contentH), laidItems),
      );
      groupX += groupW + RibbonGeometry.groupGap;
    }

    return RibbonLayout(
      width: width,
      height: height,
      tabs: tabs,
      groups: groups,
      collapseChevron: chevron,
      collapsed: collapsed,
    );
  }
}
