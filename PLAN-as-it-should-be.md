# PLAN — as it should have been

> The idealised, retrospective plan for `jaspr-ribbon-toolbar`: a canvas-rendered
> MS Office–style ribbon for Jaspr (ported from Xojo `XjRibbon`), a standalone
> visual designer, and a `.ribbon` language server. This is the plan we *should*
> have started with — it folds in every lesson from `retrospective.md` so the
> traps are **preempted**, not discovered.

---

## 1. Goal & non-goals

**Goal.** Ship a reusable `<canvas>` ribbon component for any Jaspr web app,
behaving identically to the Xojo `XjRibbon`, plus a visual designer that
produces self-contained `.ribbon` bundles, plus an LSP server for those bundles.

**Non-goals (explicit).**

- No DOM/CSS reimplementation of the ribbon — **canvas-only** (matches Xojo).
- No KeyTip keyboard navigation on web (web is mouse-driven — Xojo Phase 4 decision).
- No native OS widgets — pure Canvas 2D rendering throughout.
- No server-side rendering of the ribbon (it's a client `<canvas>`).

---

## 2. Reference material (read before any code)

- **Xojo source of truth:** `/Users/worajedt/XjRibbon-main` — `README.md`,
  `DEV_PLAN.md`, `LESSONS_LEARNED.md`, `.planning/`.
- **Control catalogue:** `image ref/explorer_ribbon_toolbar.json` — every
  control kind (Button/Toggle/CheckBox/SplitButton/DropDownButton/Gallery).
- **Jaspr for AI:** `https://jaspr.site/llms.txt`.
- **LSP:** `https://pub.dev/packages/lsp_server`.

**First deliverable of the project:** a half-page summary of the 7 control
types, the `.ribbon` v2.0 schema, and the Xojo event contract. No rendering
code is written until this exists and is reviewed.

---

## 3. Architecture decisions (decide once, up front)

These are the decisions the original plan discovered reactively. Lock them
before M1.

| # | Decision | Rationale |
|---|----------|-----------|
| AD-1 | **Two-barrel library split.** `jaspr_ribbon_toolbar.dart` = VM-pure (model, layout, painter, `DrawSurface`). `web.dart` = `package:web` only (Canvas 2D surface, controller). | Web code (`JSAny`) breaks VM tests and is unusable by the console LSP. This was the #1 recurring trap. |
| AD-2 | **Canvas-first rendering.** Port Xojo `Paint`/`LayoutTabs`/`HitTest` → `RibbonLayout` + `RibbonPainter` over a `DrawSurface` abstraction. | 1:1 visual port; identical cross-browser rendering; reuses battle-tested Xojo logic. |
| AD-3 | **Component renders the element; a controller drives it.** `RibbonToolbar` renders `<canvas>`; `RibbonCanvasController` paints + emits sealed `RibbonEvent`s. | Mirrors Xojo's Canvas+event-loop split; keeps markup declarative, painting imperative. |
| AD-4 | **Immutable model + `copyWith`; mutations return new instances.** | Diffable, serialisable, reusable by renderer/designer/LSP. |
| AD-5 | **`.ribbon` v2.0 schema is self-contained:** structure **and** an optional embedded `icons` map (`IconAsset` = kind + data URL). | A saved bundle carries its own assets — no orphan iconKeys. |
| AD-6 | **Icons referenced by string `iconKey` → `IconRegistry`.** | Solves the Xojo "Picture object wiring" pain point; keeps the model pure data. |
| AD-7 | **Contextual tabs revealed by context-group name** (`showContextGroup`/`hideContextGroup`). | Mirrors Xojo `ShowContextualTabs`. |
| AD-8 | **Dropdown menus are canvas-rendered overlays** (a second `<canvas>`), anchored to the button, with viewport flip/clamp. | Consistency with the canvas ribbon; not clipped; matches the user's mental model. |
| AD-9 | **Pub workspace (`resolution: workspace`), no melos** for resolution. | Native, sufficient. |
| AD-10 | **Harness gate = `make verify`** (format-check + `--fatal-infos` analyze + test). | One portable contract across Codex/Claude/CI. |

---

## 4. Repo / workspace layout (target)

```
jaspr-ribbon-toolbar/
├── AGENTS.md  Makefile  tool/*.sh   ← harness (portable)
├── pubspec.yaml (workspace), analysis_options.yaml (jaspr_lints plugin)
├── api/        ← generated dartdoc (run from the package dir)
├── docs/       ← schema, porting notes, screenshots
├── tutorial/   ← 3 markdown guides + 3 runnable apps + _tool (bundle gen)
├── packages/
│   ├── jaspr_ribbon_toolbar/  (model + render + component; VM-pure + web.dart)
│   └── jaspr_ribbon_lsp/      (validator + language helpers + stdio server)
├── apps/
│   ├── jaspr_ribbon_example/  (live interactive demo)
│   └── jaspr_ribbon_designer/ (visual designer)
└── editors/vscode/            (LSP extension scaffold)
```

---

## 5. Milestones

Each milestone ends with: **green `make verify`** + a **vision-verified screenshot
of the *user path*** (not just the render) + a short demo.

### M0 — Environment & interop hardening spike  *(NEW — the biggest planning fix)*

**Goal:** de-risk the toolchain and the web/Dart boundary *before* writing the
renderer, so M2 isn't blocked by infrastructure surprises.

**Deliverables:**

- Pub workspace resolves; `jaspr_lints` registered as a **plugin** (not an
  `include:` — that file doesn't exist).
- **Build/run path pinned:** try `jaspr serve`; if the build daemon fails on
  Homebrew Dart ("failed to verify the surrounding Dart SDK"), adopt and
  **document** the `dart run build_runner build --release -o build` + static-serve
  fallback. Note the script-tag-stripping quirk and the re-injection step.
- **Interop cheat-sheet proven** with a throwaway spike: a `<canvas>` rendered
  via `Component.element(tag:'canvas')`, painted from a `*.client.dart` via
  `package:web`. Record the exact rules: strings are plain `String` **except**
  `fillStyle`/`strokeStyle` (`.toJS`); `addEventListener` closure `.toJS`;
  `textContent` to clear; `HTMLSelectElement.value` is `String`.
- **VM-pure boundary test:** a trivial model class in the main barrel +
  `package:web` code in `web.dart`; confirm `dart test` (VM) passes and a
  browser build compiles. *This proves AD-1 before it's expensive.*
- **Client-mode layout rule:** confirm the App root `<div>` needs
  `.app-root{flex:1;min-height:0;display:flex;flex-direction:column}` to fill
  `100vh` (preempts the floating-footer bug).
- `make verify`, `make doctor`, `make docs` (`dart doc` from the package dir).

**Acceptance:** a "hello canvas" app runs in a browser, painted green, with a
passing VM test alongside it. **No ribbon code yet.**

### M1 — Foundation (pure model + harness)

**Goal:** the shared contract — model, JSON, events, colours, `IconRegistry`,
component shell, validator, harness.

**Deliverables:** `RibbonDefinition/Tab/Group/Item/MenuItem/IconAsset`;
all 7 control kinds + JSON v2.0 round-trip; sealed `RibbonEvent`;
`RibbonColors` (exact `ResolveColors` palette); `IconRegistry`; `RibbonToolbar`
canvas shell; `RibbonCanvasController` skeleton; LSP `validateRibbonSource`;
`AGENTS.md`.

**Acceptance:** 100% VM-tested model + serializers; `make verify` green;
`make lint-ribbon` validates `examples/explorer.ribbon`.

**Traps preempted:** schema "finalised" too early — **leave `icons` optional
from day one** (AD-5) so adding embedded assets later isn't a schema change.

### M2 — Canvas renderer

**Goal:** port the Xojo paint/layout/hit-test to Canvas 2D, end-to-end
interactive.

**Deliverables:** `RibbonGeometry` (all `k*` constants); `RibbonLayout`
(port `LayoutTabs`, incl. 3-per-column batching, separator gaps, split body/arrow
rects); `RibbonPainter` (port every `Draw*`); `WebCanvasSurface`;
`RibbonCanvasController` (paint + port `MouseDown/Move/Up/Exit` → events);
canvas-rendered dropdown overlay (AD-8); runnable `apps/jaspr_ribbon_example`.

**Acceptance — verify the USER PATH, not just the render:**
- click a tab → `TabChangedEvent` and the band switches;
- click a **split-button ▾** → the menu opens (the `pressedOnArrow` press→release
  preservation bug is a named acceptance test);
- hover/collapse/checkbox-toggle all dispatch correctly.

**Traps preempted:** imperative event state must be captured at `mouseDown` and
**read before** any state reset in `mouseUp`; dropdown overlay must anchor to the
button's bottom-left with viewport flip/clamp; HiDPI via `setTransform`-equivalent
(setting `canvas.width` resets the ctx, then `scale(dpr)` — idempotent on resize).

### M3 — Component polish

**Goal:** runtime configurability + real assets.

**Deliverables:** dark mode (`setColors`/`setDarkMode`); contextual tabs
(`showContextGroup`/`hideContextGroup`/`toggleContextGroup` + accent wash);
HiDPI crispness; `setActiveTab`/`getToggleState`/`setToggleState`;
`setDefinition`/`setIcons`/`resize`; **real SVG icons** in the example via
`IconRegistry`.

**Acceptance:** light + dark screenshots; contextual green-accent tab shows;
icons are real glyphs, not placeholder rectangles.

### M4 — Visual designer

**Goal:** a standalone Jaspr app that produces self-contained `.ribbon` bundles.

**Deliverables:** 3-row layout (full-width preview · toolbar · 3-pane
structure/inspector/icons); add/delete all node types; inspector edits
caption/**`[a-z.]`-validated tags**/iconKey/tooltip/itemType/menuItems; **icon
asset manager** (upload SVG/PNG, click-to-rename, `.1`/`.2` dedupe); live
preview that re-paints on edit; drag-to-reorder; New/Save/Load; footer pinned.

**Acceptance — focus bug is a named test:** typing in the Caption field **keeps
focus** (the "quiet refresh" vs "structural refresh" split is explicit); saving
embeds icons; loading restores them.

**Traps preempted:** the rebuild-on-keystroke focus loss — separate "value
update" (update model + preview only) from "structural change" (rebuild
inspector); App root must fill the body (M0 rule).

### M5 — `.ribbon` language server

**Goal:** editor-grade validation + completion + hover.

**Deliverables:** `textDocument/publishDiagnostics` on open/change (Full sync);
completion for `itemType` (7 tokens) and `iconKey` (from the document); hover
docs; CLI `--validate-stdin`; VS Code extension scaffold; pure logic in `lib/`
(no transport) so the designer can reuse it.

**Acceptance:** smoke test over stdio — `initialize` → capabilities; `didOpen`
with a bad `itemType` publishes the right diagnostic; completion returns tokens
inside an `"itemType"` value.

**Traps preempted:** `lsp_server`'s `onHover` is typed `Future<Hover>`
(non-nullable) — register hover on `peer` directly to return a real `null`;
`TextDocumentContentChangeEvent` is an `Either2` (unwrap with `.map`).

---

## 6. Testing strategy

- **Model/logic: 100% VM** (fast, headless). Keep the renderer's layout/painter
  VM-testable via the `DrawSurface` abstraction + a recording surface.
- **Designer:** extract its pure "brain" into a VM-tested module
  (`designer_logic.dart`) — DOM stays browser-only.
- **Acceptance = user path:** every interactive feature has a manual/visual
  check that exercises a real click, not just a programmatic open.
- **No lying screenshots:** if a feature is force-opened for a screenshot, also
  prove the click path works.

---

## 7. Risk register (traps to preempt — the heart of this plan)

| Risk | Preempted by |
|------|--------------|
| `package:web` `JSAny` breaks VM tests | AD-1 two-barrel split; M0 boundary test |
| Jaspr build daemon fails on Homebrew Dart | M0 fallback pinned + documented |
| `jaspr_lints` mis-configured as `include:` | M0 registers it as a `plugin` |
| `<canvas>` isn't a generated HTML helper | M0 spike uses `Component.element` |
| Floating footer (client-mode root) | M0 `.app-root` rule |
| `fillStyle`/`strokeStyle` need `.toJS` | M0 interop cheat-sheet |
| Split-button ▾ never opens (state reset too early) | M2 named acceptance test |
| Focus loss while typing in designer | M4 quiet-vs-structural refresh rule |
| `null as Hover` throws at runtime | M5 register hover on `peer` |
| Schema churn when adding icons | AD-5 `icons` optional from M1 |
| Dropdown renders outside canvas / wrong anchor | AD-8 canvas overlay, button-anchored |

---

## 8. Deferred / optional (state explicitly, don't let them drift)

- **`.zip` sidecar export** (loose SVG/PNG + `ribbon.json`) — only if data-URL
  bundles prove too verbose for version control. Do **not** add the `archive`
  dependency until this is green-lit (avoids an unused-dep loose end).
- **Browser-level designer smoke test** (`jaspr_test`/chrome) — nice-to-have
  after the pure-logic tests are green.
- **AST-aware LSP completion/hover** — the line-based heuristic is fine for v1.
- **`pub.dev` publish + versioned VS Code `.vsix`** — the gate to "1.0".

---

## 9. Definition of Done

- `make verify` green (format + `--fatal-infos` analyze + all tests).
- Each milestone has a vision-verified screenshot of the **user path**.
- `AGENTS.md` + `docs/` + `tutorial/` (3 guides + 3 runnable apps) reflect
  current reality.
- LSP smoke test passes over stdio; VS Code scaffold builds with `npm install`.
- No unused dependencies; no orphan loose ends in the plan's "deferred" list
  unless explicitly marked deferred.

---

## TL;DR — what this plan changes vs. the original

1. **Adds M0 (environment + interop spike)** before any rendering — the single
   biggest fix. Most "surprises" were toolchain/boundary issues, not domain
   issues.
2. **Front-loads a risk register** so traps are designed around, not stumbled on.
3. **Locks 10 architecture decisions up front** (esp. the VM-pure/`web.dart`
   split and the component-vs-controller separation).
4. **Makes acceptance criteria exercise the user path** — no more screenshots
   that lie.
5. **States optionals as deferred-with-a-gate**, so half-finished work
   (e.g. an unused `archive` dep) can't accumulate unnoticed.
