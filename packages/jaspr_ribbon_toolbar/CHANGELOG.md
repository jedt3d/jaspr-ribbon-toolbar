# Changelog

All notable changes to this project are documented here.
Formats follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.1] — 2026-06-30

- Package README updated: designer screenshot + clear scope statement
  (component-only; designer is a separate download from GitHub Releases).
- Tutorial files formatted (CI compliance).

## [0.5.0] — 2026-06-30

First tagged release. The full MS Office–style canvas ribbon for Jaspr, the
visual designer, and the `.ribbon` language server — all milestones M1–M5
complete, `make verify` green (53 Dart files, ~6,950 LOC, 223 test assertions).

### Component (`packages/jaspr_ribbon_toolbar`)
- Canvas-rendered ribbon (1:1 port of Xojo `XjRibbon`), all 7 control kinds
  (large/small/dropdown/splitbutton/toggle/checkbox/separator), tabs, groups,
  separators, hover/pressed, collapse chevron, dark mode, contextual tabs.
- Pure-Dart model + `.ribbon` v2.0 JSON (de)serialisation (self-contained
  bundles with embedded `IconAsset` SVG/PNG).
- `RibbonCanvasController` imperative driver: paint + pointer→`RibbonEvent`
  translation, canvas-rendered dropdown menus, HiDPI, `setIcons`/`setColors`/
  `setDarkMode`/`setActiveTab`/`getToggleState`/`setToggleState`/`resize`/
  `setDefinition`/`showContextGroup`/`hideContextGroup`/`toggleContextGroup`.
- `IconRegistry` (resolves `iconKey` → SVG/PNG — solves the Xojo icon pain point).

### Designer (`apps/jaspr_ribbon_designer`)
- 3-row layout (full-width live preview · toolbar · structure/inspector/icons).
- Add/delete all node types; inspector edits caption/`[a-z.]`-validated tag/
  iconKey/tooltip/itemType/menu items; focus-preserving realtime preview.
- Icon asset manager (upload SVG/PNG, click-to-rename, `.1`/`.2` dedupe),
  drag-to-reorder, New/Save/Load self-contained `.ribbon` bundles.

### Language server (`packages/jaspr_ribbon_lsp`)
- Diagnostics on open/edit, `itemType`/`iconKey` completion, hover docs;
  VS Code extension scaffold; `--validate-stdin` CLI.

### Docs
- `tutorial/` (3 guides + 3 runnable apps), `docs/`, generated `api/`,
  `AGENTS.md`, `retrospective.md`, `PLAN-as-it-should-be.md`.

### Added — milestone 1 (foundation)
- Pure-Dart typed data model (`RibbonDefinition`, `RibbonTab`, `RibbonGroup`,
  `RibbonItem`, `RibbonMenuItem`, `RibbonItemType`) with no Jaspr dependency,
  reusable by the renderer, designer, and LSP server.
- `.ribbon` JSON v2.0 (de)serialization supporting all seven control kinds:
  `large`, `small`, `dropdown`, `splitbutton`, `toggle`, `checkbox`, `separator`.
- Event model (`ItemPressedEvent`, `DropdownMenuActionEvent`,
  `CollapseStateChangedEvent`, `TabChangedEvent`) mirroring the Xojo events.
- `RibbonColors` light/dark palette ported from Xojo's `ResolveColors`, with
  CSS `#hex` / `rgba()` formatters.
- `IconRegistry` resolving `iconKey` → SVG/PNG assets — the documented solution
  to the Xojo icon pain point.
- `RibbonToolbar` Jaspr component shell rendering the `<canvas>` element with
  accessibility attributes (paint loop lands in milestone 2).
- Unit tests for the model, JSON round-trips, and colour helpers.
- Dart pub-workspace layout, `AGENTS.md`, and a Makefile/shell harness.

### Added — milestone 2 (canvas renderer)
- `RibbonGeometry` — every `k*` layout constant ported from `XjRibbon.xojo_code`.
- `DrawSurface` abstraction + `RibbonLayout` (pure-Dart port of `LayoutTabs`,
  VM-tested) + `RibbonPainter` (port of `DrawLargeButton`/`DrawSmallButton`/
  `DrawDropdownButton`/`DrawCheckBoxItem`/`DrawTabStrip`/`DrawGroups`/
  `DrawCollapseChevron`).
- `WebCanvasSurface` (Canvas 2D impl) and an imperative `RibbonCanvasController`
  that paints and ports the Xojo `MouseDown/Move/Up/Exit` flow into
  `RibbonEvent`s, with a popup menu for dropdown / split-arrow clicks.
- `apps/jaspr_ribbon_example` — a runnable Jaspr client app rendering
  `explorer.ribbon` into a live, interactive `<canvas>`.
- `web.dart` barrel split so the main barrel stays VM-testable.

### Added — milestone 3 (component polish)
- Runtime dark-mode toggle: `RibbonCanvasController.setColors` / `setDarkMode`.
- Contextual tabs: `showContextGroup` / `hideContextGroup` /
  `toggleContextGroup`, with accent wash + top bar in the painter, and a
  `visibleContextGroups` parameter on `RibbonLayout.compute`.
- HiDPI backing-store scaling for crisp rendering on retina displays.
- Programmatic control: `setActiveTab`, `getToggleState`, `setToggleState`,
  `setDefinition` (for live-preview updates from the designer).
- `RibbonColors.toCssRgbaWith` alpha helper.
- Real SVG line-icons in the example app; dark-mode + contextual-tab demo
  controls; layout test for contextual-tab visibility.

### Added — milestone 5 (bundle assets + LSP)
- **Embedded icon assets**: `RibbonDefinition.icons` (`Map<String, IconAsset>`)
  + `IconAsset`/`IconAssetKind`. The `.ribbon` bundle now carries its own SVG/PNG
  data URLs (`"icons": { key: { "kind": "svg"|"png", "data": "data:..." } }`),
  so saved bundles are self-contained. Round-tripped by the serializer; the
  designer embeds the icon library on Save and restores it on Load.
- Version bump to `0.2.0`.

### Added — milestone 4 (visual designer)
- `apps/jaspr_ribbon_designer` — a standalone Jaspr client app with a 4-panel
  layout (live `<canvas>` preview · structure tree · inspector · icons).
- Add/delete tabs, groups, and all seven item types via the Add-bar dropdown.
- Inspector edits caption/tag/itemType/enabled/tooltip/iconKey and menu items;
  the canvas preview re-paints live via `RibbonCanvasController.setDefinition`.
- **Icon asset manager**: upload SVG/PNG into a library, click to assign to the
  selected item, iconKey picker in the inspector, real icons render in the
  preview via `RibbonCanvasController.setIcons`.
- **Contextual tabs**: per-tab `isContextual` / `contextGroup` / `accentColor`
  fields; contextual tabs are revealed in the preview.
- **Drag-to-reorder** nodes within the structure tree (same-level moves).
- **Responsive preview**: `RibbonCanvasController.resize` scales the canvas to
  fit its panel; canvas-rendered dropdown menus (split-arrow / dropdown).
- New / Save `.ribbon` (JSON download) / Open (file upload).
