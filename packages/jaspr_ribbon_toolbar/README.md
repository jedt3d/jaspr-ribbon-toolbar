# jaspr_ribbon_toolbar

[![Pub](https://img.shields.io/badge/pub-0.5.1-blue)](https://pub.dev/packages/jaspr_ribbon_toolbar)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

An **MS Office–style ribbon toolbar** component for [Jaspr](https://jaspr.site/)
web apps, rendered to an HTML5 `<canvas>`. A direct port of the Xojo
[`XjRibbon`](https://github.com/jedt3d/XjRibbon) library.

![Light mode ribbon](https://raw.githubusercontent.com/jedt3d/jaspr-ribbon-toolbar/main/docs/screenshots/toolbar-light.png)

---

## What's in this package

This pub.dev package contains the **reusable ribbon component** — the library
your Jaspr app depends on. It does **not** include the visual designer or the
example apps (those live in the [GitHub repository](https://github.com/jedt3d/jaspr-ribbon-toolbar)).

| ✅ In this package | 📦 Separate download from [GitHub](https://github.com/jedt3d/jaspr-ribbon-toolbar) |
|---|---|
| Pure-Dart data model + `.ribbon` JSON serializers | **Visual designer** (standalone Jaspr app) |
| Canvas renderer (layout, painter, surface) | Example app (live interactive demo) |
| `RibbonCanvasController` (paint + event dispatch) | `.ribbon` language server (LSP) |
| `IconRegistry`, `RibbonColors` (light/dark palettes) | 3-part tutorial with 3 runnable apps |
| 8 test files (223 assertions) | Generated API docs |

---

## Visual designer — build ribbons without code

The **visual designer** is a standalone web app for designing ribbons visually:
upload SVG/PNG icons, edit the structure, assign tags, and save a
self-contained `.ribbon` bundle. It runs in any browser — no Dart toolchain
needed if you download the prebuilt.

![Visual designer](https://raw.githubusercontent.com/jedt3d/jaspr-ribbon-toolbar/main/docs/screenshots/designer-full.png)

**Get it:**

- **Prebuilt** (no Dart needed): download `jaspr_ribbon_designer-0.5.0.zip` from
  [GitHub Releases](https://github.com/jedt3d/jaspr-ribbon-toolbar/releases/tag/v0.5.0),
  unzip, and serve with any static server:
  ```bash
  python3 -m http.server -d web 8000
  ```
- **From source**: clone the repo and `cd apps/jaspr_ribbon_designer && jaspr serve`

---

## Quick start

```bash
dart pub add jaspr_ribbon_toolbar
```

```dart
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

final ribbon = RibbonDefinition(tabs: [
  RibbonTab(caption: 'Home', groups: [
    RibbonGroup(caption: 'Clipboard', items: [
      RibbonItem.large(caption: 'Paste', tag: 'clipboard.paste', iconKey: 'paste'),
      RibbonItem.small(caption: 'Cut', tag: 'clipboard.cut', iconKey: 'cut'),
    ]),
  ]),
]);
```

Render the `<canvas>`, then drive it:

```dart
RibbonCanvasController(
  canvas: canvasElement,
  definition: ribbon,
  colors: RibbonColors.light,
  onEvent: (event) {
    switch (event) {
      case ItemPressedEvent(:final tag):              handleCommand(tag);
      case DropdownMenuActionEvent(:final menuItemTag): handleCommand(menuItemTag);
      case CollapseStateChangedEvent():               /* … */
      case TabChangedEvent():                         /* … */
    }
  },
).attach();
```

Load a `.ribbon` bundle (self-contained, icons embedded):

```dart
final ribbon = RibbonDefinition.fromJsonString(jsonString);
```

---

## Features

- **All seven control kinds**: large / small / dropdown / splitbutton / toggle /
  checkbox / separator.
- **Tab-based navigation** with hover states and **contextual tabs**.
- **Collapse/expand** via chevron or double-click.
- **Dark mode** — runtime-toggleable port of Xojo's `ResolveColors` palette.
- **SVG/PNG icons** by string key (`IconRegistry`).
- **Canvas-rendered dropdown menus** — anchored, viewport-aware.
- **HiDPI** backing-store scaling for crisp rendering on retina.
- **Sealed event API** — exhaustive `switch` over `RibbonEvent`.

---

## Documentation

- **[Tutorial (3 parts + 3 runnable apps)](https://github.com/jedt3d/jaspr-ribbon-toolbar/tree/main/tutorial)**
- **[`.ribbon` schema reference](https://github.com/jedt3d/jaspr-ribbon-toolbar/blob/main/docs/schema.md)**
- **[Xojo → Dart porting guide](https://github.com/jedt3d/jaspr-ribbon-toolbar/blob/main/docs/porting-from-xojo.md)**
- **[Full source + API docs](https://github.com/jedt3d/jaspr-ribbon-toolbar)**

## License

MIT — see [LICENSE](LICENSE).
