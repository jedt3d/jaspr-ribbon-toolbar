# jaspr_ribbon_toolbar

[![Pub](https://img.shields.io/badge/pub-0.5.0-blue)](https://pub.dev/packages/jaspr_ribbon_toolbar)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

An **MS Office–style ribbon toolbar** component for [Jaspr](https://jaspr.site/)
web apps, rendered to an HTML5 `<canvas>`. A direct port of the Xojo
[`XjRibbon`](https://github.com/jedt3d/XjRibbon) library.

![Light mode](https://raw.githubusercontent.com/jedt3d/jaspr-ribbon-toolbar/main/docs/screenshots/toolbar-light.png)

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

## Quick start

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
      case ItemPressedEvent(:final tag):  handleCommand(tag);
      case DropdownMenuActionEvent(:final menuItemTag): handleCommand(menuItemTag);
      case CollapseStateChangedEvent():   /* ... */
      case TabChangedEvent():             /* ... */
    }
  },
).attach();
```

Load a `.ribbon` bundle (self-contained, icons embedded):

```dart
final ribbon = RibbonDefinition.fromJsonString(jsonString);
```

## Documentation

- **[Tutorial (3 parts + 3 runnable apps)](https://github.com/jedt3d/jaspr-ribbon-toolbar/tree/main/tutorial)**
- **[`.ribbon` schema reference](https://github.com/jedt3d/jaspr-ribbon-toolbar/blob/main/docs/schema.md)**
- **[Xojo → Dart porting guide](https://github.com/jedt3d/jaspr-ribbon-toolbar/blob/main/docs/porting-from-xojo.md)**
- **[API reference](https://github.com/jedt3d/jaspr-ribbon-toolbar/tree/main/api)**

## License

MIT — see [LICENSE](LICENSE).
