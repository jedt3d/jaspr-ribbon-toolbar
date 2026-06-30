# jaspr-ribbon-toolbar — Tutorials

A practical, end-to-end guide to embedding an MS Office–style **canvas ribbon**
into any [Jaspr](https://jaspr.site) web app, driving its events, and evolving
it as requirements change. All code below matches the real API in this repo
(component `RibbonToolbar`, the `RibbonCanvasController`, the `.ribbon` bundle,
and the visual designer).

| # | Tutorial | You'll learn |
|---|----------|--------------|
| 1 | [Embed the ribbon in your Jaspr app](01-embed-in-your-app.md) | Design a ribbon visually → save a `.ribbon` bundle → render + drive it in your own page. |
| 2 | [Events, toggles & contextual tabs](02-events-toggles-contextual.md) | Handle button/dropdown/collapse/tab events, read & set toggle state, reveal contextual tabs, sync dark mode. |
| 3 | [Real-life change request](03-change-request-scenario.md) | A product change lands on a shipped app — do the visual change in the designer **and** the behaviour change in code. |

## Runnable source — one app per stage

Each stage ships as a complete, runnable Jaspr app under `tutorial/`. `cd` in and
`jaspr serve` (or the static-build fallback below) to see exactly what the
tutorial describes:

| App | Stage | Highlights |
|-----|-------|------------|
| [`01-basic-app/`](01-basic-app/) | Tutorial 1 | Loads `assets/ribbon.bundle.json` at runtime, renders the canvas ribbon with real icons, logs every event. |
| [`02-events-app/`](02-events-app/) | Tutorial 2 | Adds a command map, toggle/checkbox state panel, a contextual-tab toggle, and a dark-mode button. |
| [`03-change-request-app/`](03-change-request-app/) | Tutorial 3 | The CR-1042 result: a new **Insert → Table** button, **Copy file** (renamed tag), **Hidden items** drives the file list, and the ribbon follows `prefers-color-scheme`. |

Each app's `web/assets/ribbon.bundle.json` is **self-contained** (icons embedded
as data URLs). To regenerate them after editing the definitions:

```bash
dart tutorial/_tool/bin/gen_bundles.dart
```

```bash
# Run any of them:
cd tutorial/01-basic-app && jaspr serve     # → http://localhost:8080

# Fallback if `jaspr serve` hits the build-daemon issue:
dart run build_runner build --release -o build
python3 -m http.server -d build/web 8000
```

> **Architecture in one paragraph.** The `RibbonToolbar` Jaspr component renders
> a single `<canvas>` element (sized, with ARIA attributes). The actual painting
> and pointer-event handling is done imperatively by the
> `RibbonCanvasController`, which you attach to that canvas from a `*.client.dart`
> entrypoint. The component places the canvas in the DOM; the controller paints
> it and translates clicks into `RibbonEvent`s. This mirrors how the original
> Xojo `XjRibbon` worked (a Canvas control + an imperative paint/event loop).

## Prerequisites

- The Dart SDK (3.8+) and the [Jaspr CLI](https://jaspr.site/docs/dev/cli):
  `dart pub global activate jaspr_cli`.
- This repo, because `jaspr_ribbon_toolbar` is not yet on pub.dev. From your app:

  ```yaml
  dependencies:
    jaspr: ^0.23.1
    jaspr_ribbon_toolbar:
      path: ../path/to/jaspr-ribbon-toolbar/packages/jaspr_ribbon_toolbar
    web: ^1.1.1   # only needed by the imperative client controller
  ```

  (Once published this becomes `jaspr_ribbon_toolbar: ^0.2.0`.)

## Run the reference apps

```bash
# The live, interactive ribbon (Home/View tabs, real SVG icons, dropdown menus)
cd apps/jaspr_ribbon_example && jaspr serve

# The visual designer (build a ribbon, manage icons, save a .ribbon bundle)
cd apps/jaspr_ribbon_designer && jaspr serve
```

> If `jaspr serve` complains about the build daemon (a known issue with some
> Homebrew Dart installs), fall back to a static build:
> `dart run build_runner build --release -o build` then serve `build/web/`
> with any static server (`python3 -m http.server`).

Start with **Tutorial 1** →
