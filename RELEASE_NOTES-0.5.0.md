# v0.5.0 — First tagged release

The MS Office–style **canvas ribbon for Jaspr** (a 1:1 port of the Xojo
`XjRibbon`), the standalone **visual designer**, and the `.ribbon` **language
server**. Milestones M1–M5 complete; `make verify` green (53 Dart files,
~6,950 LOC, 223 test assertions).

## Release assets

| Asset | What it is | How to use |
|-------|------------|------------|
| **`jaspr_ribbon_toolbar-0.5.0.tar.gz`** | The reusable component package (source). | Drop into your pub cache, or reference by `path:` in your Jaspr app's `pubspec.yaml`. |
| **`jaspr_ribbon_designer-0.5.0.zip`** | The visual designer, **prebuilt** (static `web/` bundle) — no Dart toolchain needed. | Unzip and serve: `python3 -m http.server -d web 8000`, then open `http://localhost:8000`. Design a ribbon → **Save .ribbon**. |
| **`jaspr-ribbon-toolbar-0.5.0-source+docs.tar.gz`** | Full source + generated API docs + tutorials + retrospective + plan. | Read/extend; regenerate docs with `make docs`. |

## What's inside

- **Component** — all 7 control kinds (large/small/dropdown/splitbutton/toggle/
  checkbox/separator), tabs, groups, separators, hover/pressed, collapse
  chevron, dark mode, contextual tabs, HiDPI, real SVG/PNG icons via
  `IconRegistry`, canvas-rendered dropdown menus. Sealed `RibbonEvent`s
  (`ItemPressed`/`DropdownMenuAction`/`CollapseStateChanged`/`TabChanged`).
- **Designer** — 3-row layout (full-width live preview · toolbar ·
  structure/inspector/icons); add/delete all node types; `[a-z.]`-validated tags;
  icon asset manager (upload/rename/dedupe); drag-to-reorder; focus-preserving
  realtime preview; self-contained `.ribbon` save/load (icons embedded).
- **Language server** — diagnostics on open/edit, `itemType`/`iconKey`
  completion, hover docs; VS Code extension scaffold; `--validate-stdin` CLI.

## Quick start (component in your app)

```yaml
dependencies:
  jaspr: ^0.23.1
  jaspr_ribbon_toolbar:
    path: ../jaspr_ribbon_toolbar   # the unpacked component archive
```

```dart
RibbonToolbar(definition: myRibbon, id: 'ribbon', width: 1000, height: 118)
```

Then drive it from a `*.client.dart` with `RibbonCanvasController` — see the
3-part tutorial in `tutorial/` (3 runnable apps included).

## Documentation

- `tutorial/README.md` → 3 guides + 3 runnable sample apps.
- `docs/schema.md` — the `.ribbon` field reference.
- `docs/porting-from-xojo.md` — Xojo → Dart mapping.
- `api/index.html` — generated API reference.
- `AGENTS.md`, `retrospective.md`, `PLAN-as-it-should-be.md`.

## Known limitations / next

- Package is `path:`-dependency only (not yet on `pub.dev`).
- LSP completion/hover are line-based (AST-aware analysis is future work).
- Optional `.zip` sidecar bundle and a browser-level designer test are deferred
  (see `retrospective.md`).

MIT licensed. — Worajedt Sitthidumrong
