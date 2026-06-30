import 'dart:convert';
import 'dart:io';

import 'package:jaspr_ribbon_toolbar/model.dart';

/// Generates the three runnable tutorial bundles (`ribbon.bundle.json`) with
/// icons embedded as base64 data URLs, so each app is a single self-contained
/// asset. Run from the repo root:
///
///   dart tutorial/_tool/bin/gen_bundles.dart
const _iconsDir = 'apps/jaspr_ribbon_example/web/icons';

IconAsset _svg(String name) {
  final bytes = File('$_iconsDir/$name.svg').readAsBytesSync();
  return IconAsset(kind: IconAssetKind.svg, data: 'data:image/svg+xml;base64,${base64Encode(bytes)}');
}

Map<String, IconAsset> _icons(List<String> names) => {for (final n in names) n: _svg(n)};

// ── Shared building blocks ──────────────────────────────────────────────────

RibbonTab _homeTab({String copyCaption = 'Copy', String copyTag = 'clipboard.copy'}) {
  return RibbonTab(
    caption: 'Home',
    groups: [
      RibbonGroup(caption: 'Clipboard', items: [
        RibbonItem.large(caption: 'Paste', tag: 'clipboard.paste', iconKey: 'paste'),
        RibbonItem.small(caption: 'Cut', tag: 'clipboard.cut', iconKey: 'cut'),
        RibbonItem.small(caption: copyCaption, tag: copyTag, iconKey: 'copy'),
      ]),
      RibbonGroup(caption: 'Organize', items: [
        RibbonItem.splitButton(caption: 'Delete', tag: 'organize.delete', iconKey: 'delete', menuItems: const [
          RibbonMenuItem(caption: 'Recycle', tag: 'organize.delete.recycle'),
          RibbonMenuItem(caption: 'Permanently delete', tag: 'organize.delete.permanent'),
        ]),
        RibbonItem.small(caption: 'Rename', tag: 'organize.rename', iconKey: 'rename'),
      ]),
    ],
  );
}

final _viewTab = RibbonTab(
  caption: 'View',
  groups: [
    RibbonGroup(caption: 'Panes', items: [
      RibbonItem.splitButton(caption: 'Navigation pane', tag: 'view.nav', iconKey: 'nav-pane', menuItems: const [
        const RibbonMenuItem(caption: 'Navigation pane', tag: 'view.nav.toggle'),
        const RibbonMenuItem(caption: 'Expand to open folder', tag: 'view.nav.expand'),
      ]),
      RibbonItem.toggle(caption: 'Preview pane', tag: 'view.preview', iconKey: 'preview-pane', isActive: false),
      RibbonItem.toggle(caption: 'Details pane', tag: 'view.details', iconKey: 'details-pane', isActive: false),
    ]),
    RibbonGroup(caption: 'Show/hide', items: [
      RibbonItem.checkBox(caption: 'Hidden items', tag: 'view.hidden', isChecked: true),
      const RibbonItem.separator(),
      RibbonItem.small(caption: 'Hide selected', tag: 'view.hide', iconKey: 'hide'),
    ]),
  ],
);

final _formatTab = RibbonTab.contextual(
  caption: 'Format',
  contextGroup: 'Picture Tools',
  accentColor: 0xFF2E7D32,
  groups: [
    RibbonGroup(caption: 'Picture Styles', items: [
      RibbonItem.large(caption: 'Crop', tag: 'pic.crop', iconKey: 'crop'),
    ]),
  ],
);

// ── Stage definitions ───────────────────────────────────────────────────────

/// Stage 1 — the simplest ribbon: one tab, three buttons.
RibbonDefinition _stage1() => RibbonDefinition(
      tabs: [
        RibbonTab(caption: 'Home', groups: [
          RibbonGroup(caption: 'Clipboard', items: [
            RibbonItem.large(caption: 'Paste', tag: 'clipboard.paste', iconKey: 'paste'),
            RibbonItem.small(caption: 'Cut', tag: 'clipboard.cut', iconKey: 'cut'),
            RibbonItem.small(caption: 'Copy', tag: 'clipboard.copy', iconKey: 'copy'),
          ]),
        ]),
      ],
      icons: _icons(['paste', 'cut', 'copy']),
    );

/// Stage 2 — adds dropdown/split, toggles, a checkbox, and a contextual tab.
RibbonDefinition _stage2() => RibbonDefinition(
      tabs: [_homeTab(), _viewTab, _formatTab],
      icons: _icons(['paste', 'cut', 'copy', 'delete', 'rename', 'nav-pane', 'preview-pane', 'details-pane', 'hide', 'crop']),
    );

/// Stage 3 — the CR-1042 result: an Insert tab with a Table button, and
/// "Copy" renamed to "Copy file" with tag `clipboard.copy.file`.
RibbonDefinition _stage3() => RibbonDefinition(
      tabs: [
        _homeTab(copyCaption: 'Copy file', copyTag: 'clipboard.copy.file'),
        RibbonTab(caption: 'Insert', groups: [
          RibbonGroup(caption: 'Table', items: [
            RibbonItem.large(caption: 'Table', tag: 'insert.table', iconKey: 'table'),
          ]),
        ]),
        _viewTab,
        _formatTab,
      ],
      icons: _icons([
        'paste', 'cut', 'copy', 'delete', 'rename', 'nav-pane', 'preview-pane', 'details-pane', 'hide', 'crop', 'table',
      ]),
    );

void _write(String path, RibbonDefinition def) {
  final out = 'tutorial/$path/web/assets/ribbon.bundle.json';
  File(out).writeAsStringSync(def.toJsonString());
  final iconCount = def.icons.length;
  stdout.writeln('wrote $out  (${def.tabs.length} tabs, $iconCount icons)');
}

void main() {
  _write('01-basic-app', _stage1());
  _write('02-events-app', _stage2());
  _write('03-change-request-app', _stage3());
}
