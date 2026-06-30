# AGENTS.md — jaspr-ribbon-toolbar

> Authoritative onboarding guide for **AI agents and human contributors** working
> in this repository. Read this first; it defines what the project is, how it is
> built, the exact commands to verify work, and the roadmap.

## 1. What this project is

`jaspr-ribbon-toolbar` is a **Microsoft Office–style ribbon toolbar component for
[Jaspr](https://jaspr.site/) web apps**, rendered to an HTML5 `<canvas>`. It is a
**direct port** of the Xojo [`XjRibbon`](https://github.com/.../XjRibbon-main)
library (Desktop + Web), which is the source of truth for behaviour, control
types, colour system, and the `.ribbon` JSON schema.

The repo contains **three cooperating projects** in one Dart pub-workspace:

| Path | Project | Status | Purpose |
|------|---------|--------|---------|
| `packages/jaspr_ribbon_toolbar` | the **reusable component** | 🟡 foundation done, renderer next | `<canvas>` ribbon for any Jaspr app |
| `packages/jaspr_ribbon_lsp` | the **`.ribbon` language server** | 🟡 validator done, LSP wire next | validation/autocomplete in editors + the designer |
| `apps/jaspr_ribbon_designer` | the **standalone visual designer** | ⬜ future | build/save/edit `.ribbon` bundles + manage SVG/PNG icons |

The **pure-Dart data model** (`RibbonDefinition`, `RibbonTab`, `RibbonGroup`,
`RibbonItem`, …) lives in the component package but has **no Jaspr dependency**,
so all three projects share one source of truth.

### Reference material

- **Xojo source of truth**: `/Users/worajedt/XjRibbon-main` (read its
  `README.md`, `DEV_PLAN.md`, `LESSONS_LEARNED.md`, `.planning/`).
- **Control-type reference**: `/Users/worajedt/XjRibbon-main/image ref/explorer_ribbon_toolbar.json`
  — a full catalogue of every control kind (Button / Toggle / CheckBox /
  SplitButton / DropDownButton / Gallery) seen in Windows File Explorer.
- **Jaspr docs for AI context**: `https://jaspr.site/llms.txt`
- **Jaspr lint/assist plugin**: `package:jaspr_lints` (see `analysis_options.yaml`).

## 2. Harness commands (READ THIS — run these, not raw `dart`)

`make` is the single entry point. The CI gate is **`make verify`**.

| Command | What it does | When to run |
|---------|--------------|-------------|
| `make pub-get` | `dart pub get` at workspace root | after pulling / changing `pubspec.yaml` |
| `make fmt` | apply `dart format` | before committing |
| `make fmt-check` | fail if anything is unformatted | part of `verify` |
| `make analyze` | `dart analyze --fatal-infos` | part of `verify` |
| `make test` | `dart test` in every member with `test/` | part of `verify` |
| **`make verify`** | **fmt-check + analyze + test** | **before every commit / PR; this is the gate** |
| `make lint-ribbon FILE=path/x.ribbon` | validate a `.ribbon` bundle via the LSP CLI | when editing `.ribbon` files |
| `make doctor` | print toolchain + workspace info | when debugging environment |
| `make docs` | generate API reference → `api/` | when shipping docs |
| `make clean` | remove `.dart_tool/`, `build/`, `api/` | when things get wedged |

> **Mandatory workflow**: after editing any code, run `make verify`. Do not
> consider a task finished until it prints `verify: ALL GREEN`. If you cannot
> find a command, add it here (this file is the source of truth).

The harness scripts live in `tool/` (`verify.sh`, `test.sh`, `lint-ribbon.sh`,
`doctor.sh`). Prefer the `make` targets; edit the scripts when behaviour changes.

## 3. Architecture

### Canvas-first rendering (the key decision)

The Xojo ribbon paints itself with `Graphics` drawing commands on a
`DesktopCanvas`/`WebCanvas`. The Jaspr port keeps this architecture: the
`RibbonToolbar` component renders a single `<canvas>` element and a painter
issues Canvas 2D context calls (`fillRect`, `roundRect`, `drawImage`, `fillText`,
…). This gives a 1:1 port of the Xojo `Paint` logic and identical rendering
across browsers, instead of a forest of DOM nodes.

Why canvas over DOM: the Xojo layout/hit-test/dark-mode code is already written
and battle-tested against a paint surface; porting to Canvas 2D is largely
mechanical, whereas a DOM/CSS reimplementation would be a from-scratch design.

### Workspace layout

```
jaspr-ribbon-toolbar/
├── AGENTS.md                      ← you are here
├── Makefile / tool/*.sh           ← harness
├── pubspec.yaml                   ← workspace root (resolution: workspace)
├── analysis_options.yaml          ← jaspr_lints plugin + strict analyzer
├── dart_test.yaml                 ← vm + chrome test platforms
├── examples/explorer.ribbon       ← sample bundle (Windows Explorer View tab)
├── docs/                          ← schema, porting notes, tutorials
├── packages/
│   ├── jaspr_ribbon_toolbar/
│   │   ├── lib/
│   │   │   ├── jaspr_ribbon_toolbar.dart   ← full public API (model + component)
│   │   │   ├── model.dart                  ← pure-Dart model (no Jaspr dep)
│   │   │   └── src/
│   │   │       ├── model/    (definition, tab, group, item, menu_item, item_type, events)
│   │   │       ├── theme/    (ribbon_colors — port of ResolveColors)
│   │   │       └── components/(ribbon_toolbar canvas shell, icon_registry)
│   │   └── test/model/        (JSON round-trip + behaviour tests)
│   └── jaspr_ribbon_lsp/
│       ├── lib/               (ribbon_validator — strict structural checks)
│       └── bin/jaspr_ribbon_lsp.dart  (LSP server over stdio + --validate-stdin CLI)
└── apps/                       ← designer app lands here (milestone 4)
```

### Data model & `.ribbon` JSON schema

The model is the shared contract. **version `2.0`**, `projectType` always
`"web"` for Jaspr. Full schema in `docs/schema.md`; the seven `itemType` tokens:

| `itemType` | Dart model | isToggle | isSplitButton | Xojo origin |
|------------|-----------|----------|---------------|-------------|
| `large` | `RibbonItem.large` | – | – | `kItemTypeLarge = 0` |
| `small` | `RibbonItem.small` | – | – | `kItemTypeSmall = 1` |
| `dropdown` | `RibbonItem.dropdown` | – | false | `kItemTypeDropdown = 2` |
| `splitbutton` | `RibbonItem.splitButton` | – | **true** | `IsSplitButton = True` |
| `toggle` | `RibbonItem.toggle` | **true** | – | `IsToggle` on large/small |
| `checkbox` | `RibbonItem.checkBox` | **true** | – | `kItemTypeCheckBox = 3` |
| `separator` | `RibbonItem.separator` | – | – | `kItemTypeSeparator = 4` |

Minimal example:
```json
{
  "version": "2.0", "projectType": "web",
  "tabs": [{ "caption": "Home", "groups": [{ "caption": "Clipboard", "items": [
    { "caption": "Paste", "tag": "clipboard.paste", "itemType": "large", "iconKey": "paste" },
    { "caption": "Hidden items", "tag": "view.hidden", "itemType": "checkbox", "isToggleActive": true }
  ]}]}]
}
```

### Icons — the solved Xojo pain point

Xojo's documented difficulty was wiring `Picture` objects (SVG/PNG) into items.
Here, items carry only a string **`iconKey`**; an `IconRegistry` maps keys →
`IconSource` (SVG markup/URL or PNG base64/URL). The renderer resolves the key
at paint time. This keeps the model serialisable, diffable, and editor-friendly.

### Events

`RibbonEvent` is a sealed type — `switch` over it exhaustively:

- `ItemPressedEvent(tag)` — Xojo `ItemPressed`
- `DropdownMenuActionEvent{itemTag, menuItemTag}` — Xojo `DropdownMenuAction`
- `CollapseStateChangedEvent(isCollapsed)` — Xojo `CollapseStateChanged`
- `TabChangedEvent(tabIndex)` — active tab changed

## 4. Conventions

- **Language**: Dart `^3.8.0` (workspace); Jaspr `^0.23.1`.
- **Style**: `dart format` is authoritative; `dart analyze --fatal-infos` must
  pass (strict casts/inference/raw-types on). The `jaspr_lints` plugin adds
  Jaspr-specific assists (`prefer_html_components`, `sort_children_last`).
- **Model purity**: anything under `lib/src/model/` and `lib/model.dart` must
  stay **Jaspr-free** so the LSP server and designer can reuse it. Import
  `package:jaspr_ribbon_toolbar/model.dart` (not the Jaspr barrel) when you only
  need data.
- **Immutability**: model classes are immutable value types with `copyWith` /
  `==` / `hashCode`. Mutations (e.g. toggling) return new instances
  (`definition.toggled(tag)`).
- **Naming**: model mirrors Xojo (`RibbonItem`, `RibbonGroup`, …); Dart-idiomatic
  camelCase; factory constructors named after the control kind
  (`RibbonItem.large`, `.splitButton`, …).
- **Tests**: pure-logic tests run on the **VM** (fast, headless). Anything
  exercising the DOM uses `jaspr_test`'s `testComponents` and runs on **chrome**.
  Keep the model 100% VM-tested so `make test` is fast and CI-friendly.
- **Comments**: dartdoc on every `public` symbol (`///`). No inline comments
  unless explaining a non-obvious porting decision (and then reference the Xojo
  source, e.g. "// mirrors Xojo HitTestItems").

## 5. Roadmap

Done items are tagged ✅; the current focus is **M2**.

- **M1 — Foundation ✅**: pub-workspace, typed model + JSON v2.0 serializers
  (all 7 control types), events, colour palette, `IconRegistry`, `RibbonToolbar`
  canvas shell, model unit tests, LSP validator, Makefile harness.
- **M2 — Canvas renderer ✅**: ported Xojo `Paint`/`LayoutTabs`/`HitTestItems`
  to a pure-Dart `RibbonLayout` + `RibbonPainter` (VM-tested), a `DrawSurface`
  abstraction with a `WebCanvasSurface` (Canvas 2D) impl, and an imperative
  `RibbonCanvasController` that paints and translates pointer events into
  `RibbonEvent`s (incl. dropdown/split popup menus). Runnable
  `apps/jaspr_ribbon_example` renders `explorer.ribbon` live.
- **M3 — Component polish ✅**: dark-mode runtime toggle (`setColors` /
  `setDarkMode`), contextual-tab show/hide (`showContextGroup` /
  `hideContextGroup` / `toggleContextGroup`) with accent wash + top bar,
  HiDPI backing-store scaling for crisp rendering, programmatic tab/toggle
  control (`setActiveTab`, `getToggleState`, `setToggleState`), real SVG
  line-icons wired through `IconRegistry` in the example app, plus demo
  controls.
- **M4 — Visual designer ✅** (`apps/jaspr_ribbon_designer`): a standalone
  Jaspr client app — 3-row layout (full-width live `<canvas>` preview · toolbar ·
  3-pane structure/inspector/icons) mirroring the Xojo designer. Add/delete tabs,
  groups and all item types; edit caption/tag/itemType/enabled/tooltip/iconKey
  and menu items (focus-preserving realtime preview); the canvas preview
  re-paints live on every edit. **Icon asset manager** (upload SVG/PNG,
  `[a-z.]`-validated keys, click-to-rename, `.1`/`.2` dedupe), drag-to-reorder,
  square UI, ruled tree, footer pinned. New / Save `.ribbon` / Open.
- **M5 — `.ribbon` language server ✅** (`packages/jaspr_ribbon_lsp`): publishes
  `validateRibbonSource` diagnostics on open/edit, completion for `itemType`
  (7 tokens) / `iconKey` (from the document), hover docs. Self-contained
  bundles via `RibbonDefinition.icons` (`IconAsset`). VS Code extension scaffold
  in `editors/vscode/`; CLI `--validate-stdin`.

## 6. Gotchas ported from Xojo (`LESSONS_LEARNED.md`)

These Xojo-specific traps do **not** apply to Dart, but the *decisions* behind
them carry over:

- **No peek on collapse** — single-click switches tab, double-click toggles
  collapse (Xojo lesson #10).
- **SplitButton hit-test** — body (≥80% width) fires action, arrow (≤20%) opens
  menu (Xojo DEV_PLAN §1).
- **Web is mouse-driven** — KeyTip keyboard nav is out of scope for web (Xojo
  Phase 4 decision); don't implement it.
- **CheckBox vs Toggle** — both toggle `isToggleActive`, but CheckBox renders a
  glyph ☐/☑ and a text row; Toggle renders a press-highlighted button.

## 7. Adding a new control type

1. Extend `RibbonItemType` (if it needs a new core type) or a flag on
   `RibbonItem`.
2. Add the `itemType` token to `allowedItemTypes` in the LSP validator and to
   `RibbonItem.fromJson`/`jsonType`.
3. Add a named factory on `RibbonItem` mirroring the Xojo
   `XjRibbonGroup.AddXxx` method.
4. Add the draw branch in the painter (M2).
5. Add a JSON round-trip test in `test/model/`.
6. Bump `packages/jaspr_ribbon_toolbar/CHANGELOG.md`.

---

*Last updated: M1 complete. When the harness or architecture changes, update
this file in the same commit.*
