# Tutorial 1 — Embed the ribbon in your Jaspr app

**Goal:** take a ribbon designed in the visual designer and render it, fully
interactive, inside an arbitrary Jaspr web page.

We will:
1. Build a ribbon visually in the **designer** and save a `.ribbon` bundle.
2. Drop the bundle + icons into our app's `web/` assets.
3. Render the `<canvas>` with the `RibbonToolbar` component.
4. Drive painting + events from a `*.client.dart` entrypoint with the
   `RibbonCanvasController`.

---

## Step 1 — Design the ribbon (visual designer)

Start the designer:

```bash
cd apps/jaspr_ribbon_designer && jaspr serve
```

You get four regions:

- **Row 1** — the full-width **live preview** (the canvas ribbon).
- **Row 2** — the toolbar: `Add: [type]` + **Add** / **Delete**, then **New** /
  **Load** / **Save .ribbon**.
- **Row 3** — three panes: **Structure**, **Inspector**, **Icons**.

Build the structure:

1. **Add → Tab** → name it `Home` (click it in the tree, edit **Caption** in the
   Inspector).
2. With `Home` selected, **Add → Group** → name it `Clipboard`.
3. With `Clipboard` selected, **Add → Large button** → caption `Paste`,
   tag `clipboard.paste`. Add two **Small button**s: `Cut` (`clipboard.cut`)
   and `Copy` (`clipboard.copy`).
4. Add another group `Font`; inside it add a **Toggle** `Bold` (`font.bold`) and
   a **Checkbox** `Italic` (`font.italic`).

> **Tags** are your command identifiers — lower-case letters and dots only
> (`font.bold`). The designer enforces this as you type.

### Add real icons

In the **Icons** pane click **Upload SVG/PNG** and pick a few SVGs. They appear
in a multi-column gallery. Select an item in the tree (e.g. `Paste`), then
**click an icon card** to assign it — or pick it from the **Icon key** dropdown
in the Inspector. The live preview re-paints with the real glyph.

- **Rename** an icon by clicking its name in the gallery (validates to
  `[a-z.]`; renames every item that uses it).
- Upload a duplicate and it auto-becomes `name.1`, `name.2`… for you to rename.

### Save the bundle

Click **Save .ribbon**. You get `ribbon.bundle.json` — a **self-contained**
bundle: the structure **and** the icons embedded as data URLs:

```json
{
  "version": "2.0",
  "projectType": "web",
  "tabs": [ /* …Home, Clipboard, Paste/Cut/Copy, Font, Bold/Italic… */ ],
  "icons": {
    "paste": { "kind": "svg", "data": "data:image/svg+xml;base64,…" },
    "bold":  { "kind": "svg", "data": "data:image/svg+xml;base64,…" }
  }
}
```

> You can also hand-edit this JSON — the `.ribbon` language server
> (`packages/jaspr_ribbon_lsp`) gives you validation, `itemType`/`iconKey`
> autocomplete, and hover docs in VS Code.

---

## Step 2 — Add the bundle to your app

Assume your Jaspr app lives in `my_app/`. Copy the saved bundle into its web
assets:

```
my_app/
├── pubspec.yaml
├── web/
│   ├── index.html
│   └── assets/
│       └── ribbon.bundle.json     ← the file from Step 1
└── lib/
    └── main.client.dart
```

`pubspec.yaml`:

```yaml
name: my_app
environment:
  sdk: ^3.8.0
dependencies:
  jaspr: ^0.23.1
  jaspr_ribbon_toolbar:
    path: ../jaspr-ribbon-toolbar/packages/jaspr_ribbon_toolbar
  web: ^1.1.1
dev_dependencies:
  build_runner: ^2.10.0
  build_web_compilers: ^4.8.0
  jaspr_builder: ^0.23.1

jaspr:
  mode: client
```

`web/index.html` (the usual Jaspr client shell):

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>My App</title>
  <script defer src="main.client.dart.js"></script>
</head>
<body></body>
</html>
```

---

## Step 3 — Render the `<canvas>` with `RibbonToolbar`

The component's only job is to place a correctly-sized `<canvas>` (with the
right `role`/`aria` attributes) into the component tree. Give it a stable `id`
so the controller can find it.

`lib/app.dart`:

```dart
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return div([
      const h1([Component.text('My App')]),
      // The component renders the <canvas>; painting + events are driven
      // imperatively from main.client.dart (see Step 4).
      RibbonToolbar(
        definition: RibbonDefinition(tabs: const []), // placeholder; replaced at runtime
        id: 'ribbon',
        width: 1000,
        height: 118,
      ),
      div(id: 'stage', const []),
    ]);
  }
}
```

> We pass an empty `definition` here because the real definition (loaded from
> the bundle) is handed to the **controller** in Step 4, which is what actually
> paints. The component only needs to emit the canvas element.

---

## Step 4 — Drive it with `RibbonCanvasController`

This is where the ribbon comes alive. In a **client** entrypoint (`main.client.dart`)
we: load the `.ribbon` bundle, build an `IconRegistry` from its embedded icons,
grab the canvas by id, and attach the controller.

`lib/main.client.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:jaspr_ribbon_toolbar/web.dart';
import 'package:web/web.dart' as web;

import 'app.dart';

RibbonCanvasController? _ribbon;

Future<void> main() async {
  runApp(const App());
  // The canvas mounts synchronously; wire it on the next microtask.
  await Future<void>.microtask(() {});
  await attachRibbon();
}

Future<void> attachRibbon() async {
  // 1) Load the .ribbon bundle.
  final res = await web.window.fetch('assets/ribbon.bundle.json'.toJS).toDart;
  final jsonText = (await res.text().toDart).toDart;
  final definition = RibbonDefinition.fromJsonString(jsonText);

  // 2) Build an IconRegistry from the bundle's embedded icons.
  final icons = <String, IconSource>{};
  for (final entry in definition.icons.entries) {
    final src = entry.value.data;
    icons[entry.key] =
        entry.value.kind == IconAssetKind.svg ? IconSource.svg(src) : IconSource.png(src);
  }

  // 3) Find the canvas the component rendered and attach the controller.
  final el = web.document.getElementById('ribbon');
  if (el == null) return;
  _ribbon = RibbonCanvasController(
    canvas: el as web.HTMLCanvasElement,
    definition: definition,
    colors: RibbonColors.light,
    icons: IconRegistry.assets(icons),
    onEvent: handleEvent, // covered in Tutorial 2
  )..attach();
}

void handleEvent(RibbonEvent e) {
  // Tutorial 2 fills this in. For now, log:
  web.console.log(e.toString().toJS);
}
```

> **Why imperative?** Canvas painting is inherently imperative. The component
> keeps your markup declarative; the controller owns the paint/event loop —
> the same split the original Xojo `XjRibbon` used.

---

## Step 5 — Run

```bash
jaspr serve          # http://localhost:8080 (or whichever port it prints)
```

You should see your ribbon, with real icons, fully interactive: hover states,
tab switching, the collapse chevron, and (for dropdown/split items) popup menus.
The `.fetch` loads your bundle, so non-coders can re-skin the toolbar just by
editing `ribbon.bundle.json` (or re-saving from the designer).

---

## Recap

- **Designer** produces a self-contained `.ribbon` bundle (structure + icons).
- `RibbonToolbar` renders the `<canvas>`.
- `RibbonCanvasController` paints it and emits `RibbonEvent`s.
- The bundle is a plain JSON asset — re-design in the designer, drop the new
  file in, done.

Next: **[Tutorial 2 — events, toggles & contextual tabs](02-events-toggles-contextual.md)**
turns `handleEvent` into real behaviour.
