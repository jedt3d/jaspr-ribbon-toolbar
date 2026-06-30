# jaspr-ribbon-toolbar

[![verify](https://img.shields.io/badge/make%20verify-ALL%20GREEN-brightgreen)](Makefile)
[![Dart](https://img.shields.io/badge/Dart-%5E3.8-blue)](https://dart.dev)
[![Jaspr](https://img.shields.io/badge/Jaspr-0.23-5647C8)](https://jaspr.site)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

An **MS Office–style ribbon toolbar** component for [Jaspr](https://jaspr.site/)
web apps, rendered to an HTML5 `<canvas>`. It is a **direct port** of the Xojo
[`XjRibbon`](https://github.com/.../XjRibbon-main) library (Desktop + Web), which
is the source of truth for behaviour, control types, the colour system, and the
`.ribbon` JSON schema.

> **Status — M1 (Foundation):** the typed data model, JSON v2.0 serializers,
> events, colour palette, `IconRegistry`, the `RibbonToolbar` canvas shell, the
> `.ribbon` validator, and the harness are all done and tested. The Canvas 2D
> paint loop (M2) is the active work. See [`AGENTS.md`](AGENTS.md) for the full
> roadmap.

## Features

- **Tab-based navigation** with active / hover states and **contextual tabs**.
- **All seven control kinds** from the Windows File Explorer reference:
  large / small / dropdown / splitbutton / toggle / checkbox / separator.
- **Collapse/expand** via chevron or double-click.
- **Dark mode** via a ported `ResolveColors` palette.
- **SVG/PNG icons** by string key (`IconRegistry`) — the Xojo icon pain point,
  solved.
- **Pure-Dart data model** reusable by the renderer, the LSP server, and the
  designer — serialisable to `.ribbon` JSON.

## Quick start

```yaml
# pubspec.yaml
dependencies:
  jaspr_ribbon_toolbar: ^0.1.0
```

```dart
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

final ribbon = RibbonDefinition(
  projectType: 'web',
  tabs: [
    RibbonTab(
      caption: 'Home',
      groups: [
        RibbonGroup(
          caption: 'Clipboard',
          items: [
            RibbonItem.large(caption: 'Paste', tag: 'clipboard.paste', iconKey: 'paste'),
            RibbonItem.small(caption: 'Cut', tag: 'clipboard.cut', iconKey: 'cut'),
          ],
        ),
      ],
    ),
  ],
);
```

```dart
// In your Jaspr component tree:
RibbonToolbar(
  definition: ribbon,
  darkMode: false,
  onEvent: (event) {
    switch (event) {
      case ItemPressedEvent(:final tag):          handleCommand(tag);
      case DropdownMenuActionEvent(:final menuItemTag): handleCommand(menuItemTag);
      case CollapseStateChangedEvent():           /* … */
      case TabChangedEvent():                     /* … */
    }
  },
)
```

Load a `.ribbon` bundle directly:

```dart
final ribbon = RibbonDefinition.fromJsonString(await File('ribbon.json').readAsString());
```

## Repository layout

This is a **Dart pub-workspace** with three cooperating projects:

| Path | What |
|------|------|
| `packages/jaspr_ribbon_toolbar` | the reusable component (model + canvas shell) |
| `packages/jaspr_ribbon_lsp` | the `.ribbon` language server (validation/autocomplete) |
| `apps/jaspr_ribbon_designer` | the standalone visual designer *(planned)* |

## Developing

```bash
make pub-get      # resolve dependencies
make verify       # the CI gate: format check + analyze + test (33 tests)
make lint-ribbon FILE=examples/explorer.ribbon   # validate a .ribbon bundle
make docs         # generate the API reference → api/
```

Read **[`AGENTS.md`](AGENTS.md)** for the architecture, conventions, and the
Xojo→Dart porting notes. Tutorials live in [`docs/`](docs/).

## Acknowledgements

Ported from [XjRibbon](https://github.com/.../XjRibbon-main) by Worajedt
Sitthidumrong. Built on [Jaspr](https://jaspr.site/) by Kilian Schulte.

## License

MIT — see [LICENSE](LICENSE).
