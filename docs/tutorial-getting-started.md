# Tutorial — Build your first ribbon

This tutorial creates a ribbon matching a slice of the Windows File Explorer
"View" tab. It covers all seven control kinds, a contextual tab, JSON save/load,
and event handling. It assumes milestone 2 (the canvas renderer) is available;
the data-model parts work today.

## 1. Compose the definition imperatively

```dart
import 'package:jaspr_ribbon_toolbar/model.dart';

final ribbon = RibbonDefinition(
  projectType: 'web',
  tabs: [
    RibbonTab(
      caption: 'View',
      groups: [
        RibbonGroup(
          caption: 'Panes',
          items: [
            RibbonItem.splitButton(
              caption: 'Navigation pane',
              tag: 'view.nav',
              iconKey: 'nav-pane',
              menuItems: const [
                RibbonMenuItem(caption: 'Navigation pane', tag: 'view.nav.toggle'),
                RibbonMenuItem(caption: 'Expand to open folder', tag: 'view.nav.expand'),
              ],
            ),
            RibbonItem.toggle(caption: 'Preview pane', tag: 'view.preview', isActive: false),
            RibbonItem.toggle(caption: 'Details pane', tag: 'view.details', isActive: false),
          ],
        ),
        RibbonGroup(
          caption: 'Show/hide',
          items: [
            RibbonItem.checkBox(caption: 'File name extensions', tag: 'view.ext', isChecked: false),
            RibbonItem.checkBox(caption: 'Hidden items', tag: 'view.hidden', isChecked: true),
            const RibbonItem.separator(),
            RibbonItem.small(caption: 'Hide selected items', tag: 'view.hide', iconKey: 'hide'),
          ],
        ),
      ],
    ),
    RibbonTab.contextual(
      caption: 'Format',
      contextGroup: 'Picture Tools',
      accentColor: 0xFF2E7D32,
      groups: [
        RibbonGroup(caption: 'Picture Styles', items: [
          RibbonItem.large(caption: 'Crop', tag: 'pic.crop', iconKey: 'crop'),
        ]),
      ],
    ),
  ],
);
```

## 2. Render it in a Jaspr app

```dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) => RibbonToolbar(
        definition: ribbon,
        darkMode: false,
        icons: IconRegistry.assets(const {
          'nav-pane': IconSource.svgUrl('assets/nav-pane.svg'),
          'crop': IconSource.pngUrl('assets/crop.png'),
        }),
        onEvent: (event) {
          switch (event) {
            case ItemPressedEvent(:final tag):
              print('command: $tag');
            case DropdownMenuActionEvent(:final itemTag, :final menuItemTag):
              print('menu: $itemTag → $menuItemTag');
            case CollapseStateChangedEvent(:final isCollapsed):
              print('collapsed: $isCollapsed');
            case TabChangedEvent(:final tabIndex):
              print('tab: $tabIndex');
          }
        },
      );
}
```

## 3. Save / load as `.ribbon` JSON

```dart
import 'dart:io';

// Save
await File('my.ribbon').writeAsString(ribbon.toJsonString());

// Load
final restored = RibbonDefinition.fromJsonString(await File('my.ribbon').readAsString());
assert(restored == ribbon);
```

Validate from the command line:

```bash
make lint-ribbon FILE=my.ribbon
```

## 4. Mutate state immutably

Toggling a checkbox returns a new definition — the original is unchanged:

```dart
final next = ribbon.toggled('view.hidden');   // flips the checked state
print(next.isToggleActive('view.hidden'));    // false
print(ribbon.isToggleActive('view.hidden'));  // true (unchanged)
```

## 5. Query the structure

```dart
final item = ribbon.findItem('view.nav');     // RibbonItem?
print(item?.jsonType);                         // splitbutton
print(ribbon.contextualTabsFor('Picture Tools').length); // 1
print(ribbon.containsTag('pic.crop'));         // true
```

## What's next

- [`docs/schema.md`](schema.md) — the full `.ribbon` field reference.
- [`docs/porting-from-xojo.md`](porting-from-xojo.md) — Xojo → Dart mapping.
- [`examples/explorer.ribbon`](../examples/explorer.ribbon) — a complete sample.
