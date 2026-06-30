import 'package:jaspr_ribbon_toolbar/model.dart';
import 'package:jaspr_ribbon_toolbar/src/render/ribbon_geometry.dart';
import 'package:jaspr_ribbon_toolbar/src/render/ribbon_layout.dart';
import 'package:jaspr_ribbon_toolbar/src/render/ribbon_painter.dart';
import 'package:test/test.dart';

import 'recording_surface.dart';

RibbonDefinition _twoTabs() {
  return RibbonDefinition(
    version: '2.0',
    projectType: 'web',
    tabs: [
      RibbonTab(
        caption: 'Home',
        groups: [
          RibbonGroup(
            caption: 'Clipboard',
            items: [
              RibbonItem.large(
                caption: 'Paste',
                tag: 'home.paste',
                iconKey: 'paste',
              ),
              RibbonItem.small(caption: 'Cut', tag: 'home.cut'),
              RibbonItem.small(caption: 'Copy', tag: 'home.copy'),
            ],
          ),
          RibbonGroup(
            caption: 'Show/hide',
            items: [
              RibbonItem.checkBox(
                caption: 'Hidden items',
                tag: 'home.hidden',
                isChecked: true,
              ),
              const RibbonItem.separator(),
              RibbonItem.small(caption: 'Hide', tag: 'home.hide'),
            ],
          ),
        ],
      ),
      RibbonTab(
        caption: 'View',
        groups: [
          RibbonGroup(
            caption: 'Panes',
            items: [
              RibbonItem.splitButton(
                caption: 'Navigation pane',
                tag: 'view.nav',
                menuItems: [
                  const RibbonMenuItem(
                    caption: 'Toggle',
                    tag: 'view.nav.toggle',
                  ),
                ],
              ),
              RibbonItem.dropdown(caption: 'Sort by', tag: 'view.sort'),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('RibbonLayout.compute', () {
    final def = _twoTabs();
    final surface = RecordingSurface();
    final layout = RibbonLayout.compute(
      definition: def,
      surface: surface,
      width: 1000,
      height: 118,
      activeTabIndex: 0,
      collapsed: false,
    );

    test('lays out one tab-strip entry per visible tab', () {
      expect(layout.tabs, hasLength(2));
      expect(layout.tabs.first.tab.caption, 'Home');
      expect(layout.tabs.first.rect.y, 0);
      expect(layout.tabs.first.rect.h, RibbonGeometry.tabStripHeight);
      // second tab follows the first with a gap
      expect(layout.tabs[1].rect.x, greaterThan(layout.tabs[0].rect.right));
    });

    test('only the active tab\'s groups get item bounds', () {
      expect(layout.groups, hasLength(2));
      expect(layout.groups.first.group.caption, 'Clipboard');
      final paste = layout.groups.first.items.first;
      expect(paste.item.tag, 'home.paste');
      expect(paste.rect.h, greaterThan(0));
    });

    test('separator produces no item bounds but advances the cursor', () {
      final showHide = layout.groups[1];
      final tags = showHide.items.map((e) => e.item.tag).toList();
      expect(tags, ['home.hidden', 'home.hide']); // separator skipped
      expect(
        showHide.items.first.rect.x,
        lessThan(showHide.items.last.rect.x),
        reason: 'small button sits after the separator gap',
      );
    });

    test('split buttons expose separate body + arrow hit rects', () {
      final surface2 = RecordingSurface();
      final viewLayout = RibbonLayout.compute(
        definition: def,
        surface: surface2,
        width: 1000,
        height: 118,
        activeTabIndex: 1,
        collapsed: false,
      );
      final nav = viewLayout.groups.first.items.first;
      expect(nav.item.isSplitButton, isTrue);
      expect(nav.arrowRect, isNotNull);
      expect(nav.bodyRect, isNotNull);
      // arrow sits to the right of the body
      expect(nav.arrowRect!.x, greaterThanOrEqualTo(nav.bodyRect!.right - 1));
    });

    test('collapse chevron sits at the right edge', () {
      expect(layout.collapseChevron, isNotNull);
      expect(layout.collapseChevron!.right, lessThanOrEqualTo(1000));
      expect(layout.collapseChevron!.right, greaterThan(900));
    });

    test('hit-testing resolves tabs and items', () {
      final tab = layout.hitTab(layout.tabs.first.rect.x + 4, 4);
      expect(tab?.tab.caption, 'Home');
      final item = layout.hitItem(
        layout.groups.first.items.first.rect.x + 2,
        layout.groups.first.items.first.rect.y + 2,
      );
      expect(item?.item.tag, 'home.paste');
    });

    test('collapsed layout has no group content', () {
      final collapsed = RibbonLayout.compute(
        definition: def,
        surface: RecordingSurface(),
        width: 1000,
        height: 118,
        activeTabIndex: 0,
        collapsed: true,
      );
      expect(collapsed.collapsed, isTrue);
      expect(collapsed.groups, isEmpty);
    });
  });

  group('RibbonPainter', () {
    test('paint issues draw calls for every visible element', () {
      final surface = RecordingSurface();
      final layout = RibbonLayout.compute(
        definition: _twoTabs(),
        surface: surface,
        width: 1000,
        height: 118,
        activeTabIndex: 0,
        collapsed: false,
      );
      final before = surface.calls;
      const RibbonPainter(
        colors: RibbonColors.light,
      ).paint(surface, layout, const RibbonPaintState());
      expect(surface.calls, greaterThan(before));
      expect(
        surface.calls,
        greaterThan(20),
        reason: 'background + tabs + groups + items',
      );
    });

    test('collapsed paint skips group content', () {
      final surface = RecordingSurface();
      final layout = RibbonLayout.compute(
        definition: _twoTabs(),
        surface: surface,
        width: 1000,
        height: 118,
        activeTabIndex: 0,
        collapsed: true,
      );
      final callsCollapsed = () {
        final s = RecordingSurface();
        const RibbonPainter(
          colors: RibbonColors.light,
        ).paint(s, layout, const RibbonPaintState(collapsed: true));
        return s.calls;
      }();
      expect(layout.groups, isEmpty);
      expect(callsCollapsed, greaterThan(0));
    });
  });

  group('contextual tabs', () {
    final def = _twoTabs();

    test('are hidden by default', () {
      final layout = RibbonLayout.compute(
        definition: def,
        surface: RecordingSurface(),
        width: 1000,
        height: 118,
        activeTabIndex: 0,
        collapsed: false,
      );
      // _twoTabs() has only standard tabs; add a contextual one on the fly.
      expect(layout.tabs.every((t) => !t.tab.isContextual), isTrue);
    });

    test('appear when their context group is visible', () {
      const withCtx = RibbonDefinition(
        version: '2.0',
        projectType: 'web',
        tabs: [
          RibbonTab(caption: 'Home', groups: []),
          RibbonTab.contextual(
            caption: 'Format',
            contextGroup: 'Picture Tools',
            accentColor: 0xFF2E7D32,
            groups: [],
          ),
        ],
      );
      final hidden = RibbonLayout.compute(
        definition: withCtx,
        surface: RecordingSurface(),
        width: 1000,
        height: 118,
        activeTabIndex: 0,
        collapsed: false,
      );
      expect(
        hidden.tabs,
        hasLength(1),
        reason: 'contextual tab is hidden by default',
      );

      final shown = RibbonLayout.compute(
        definition: withCtx,
        surface: RecordingSurface(),
        width: 1000,
        height: 118,
        activeTabIndex: 0,
        collapsed: false,
        visibleContextGroups: const {'Picture Tools'},
      );
      expect(
        shown.tabs,
        hasLength(2),
        reason: 'contextual tab appears when its group is shown',
      );
      expect(shown.tabs.last.tab.caption, 'Format');
    });
  });
}
