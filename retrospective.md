# Retrospective — jaspr-ribbon-toolbar

A look back at building a canvas-rendered MS Office–style ribbon for Jaspr
(ported from the Xojo `XjRibbon`), a standalone visual designer, and a `.ribbon`
language server. Covers: (1) what was learned about authoring a Jaspr component
— distilled into skill-ready material; (2) whether the dev harness is worth
turning into a Codex plugin; (3) plan vs. actual — how well we planned, what we
missed, and the catches that bit us.

**By the numbers:** 53 Dart files · ~6,950 LOC · 223 test assertions across
8 test files · 16 screenshots · 4 tutorial docs + 3 runnable tutorial apps ·
5 milestones (M1–M5) delivered · 1 designer app · 1 LSP server.

---

## 1. What I learned about creating a Jaspr component (skill material)

These are the reusable lessons — the kernel of a future **"jaspr-component"
skill** for both Dart and Jaspr work. Each was earned the hard way on this
project.

### Architecture

1. **Split web-only code into its own library barrel.** The pure Dart model,
   layout, and painter must be **VM-pure** (no `package:web`) so they run in
   `dart test` and are reusable by non-web consumers (here: the LSP console
   server). Web-only code (the Canvas 2D controller/surface) lives in a separate
   `web.dart`. If web code leaks into the main barrel, VM tests fail with
   `'JSAny' isn't a type`. *This was the single most-repeated trap of the
   project.*
2. **Canvas-first = faithful port.** Porting Xojo's `Paint`/`LayoutTabs`/
   `HitTest` to a `DrawSurface` abstraction + `RibbonPainter` gave a 1:1 visual
   port and identical rendering across browsers, exactly as the Xojo design
   intended. Canvas over DOM was the right call.
3. **Component renders the element; a controller drives it.** The Jaspr
   `RibbonToolbar` component renders a `<canvas>`; an imperative
   `RibbonCanvasController` paints it and translates pointer events into sealed
   `RibbonEvent`s. This mirrors the original Xojo Canvas+event-loop split and
   keeps markup declarative while canvas painting stays imperative.

### Jaspr specifics (gotchas)

4. **The HTML DSL is lowercase `final class` constructors, not functions.**
   `div([...])`, `span(...)`, `select(...)` are generated classes; `<canvas>` is
   **not** generated — use `Component.element(tag: 'canvas', ...)`.
5. **Client-mode root must fill the body.** `runApp` attaches the App's root
   `<div>` to `<body>`. If that root has no sizing, it shrinks to content and
   leaves the rest of `100vh` empty (the "floating footer" bug we hit). Fix:
   `.app-root { flex:1; min-height:0; display:flex; flex-direction:column; }`.
6. **Grab the canvas after mount.** `runApp(App())` mounts synchronously; attach
   the imperative controller in a `Future.microtask` after `runApp`, finding the
   element by id.
7. **`jaspr_lints` is a `plugins:` entry, not an `include:`.**
   `include: package:jaspr_lints/package.yaml` is wrong (no such file). Declare
   it once at the workspace root under `plugins:`.
8. **Scoped `@css` needs `build_runner`/`jaspr_builder`;** a plain `<style>` in
   `index.html` does not. For a canvas component, the `<style>` approach is
   simplest.

### Environment / build

9. **The Jaspr build daemon breaks on Homebrew Dart** ("failed to verify the
   surrounding Dart SDK"). Reliable fallback: `dart run build_runner build
   --release -o build`, then serve `build/web/` statically. Document this up
   front.
10. **`build_runner` can strip `<script src="main.client.dart.js">` from
    `index.html`** in some flows. Re-inject it (or use `jaspr serve`).
11. **`dart doc` must run from the package dir**, not the workspace root, or it
    finds "no libraries to document."

### `package:web` interop

12. **String DOM props take plain `String` *except* `fillStyle`/`strokeStyle`**
    (typed `JSAny` → need `.toJS`). This cost several round trips.
13. **`addEventListener` needs a `.toJS` closure;** `Element.replaceChildren()`
    requires an arg (`textContent = ''` is the safe clear); `FileReader.result`
    is `dynamic`; `HTMLSelectElement.value` is `String`.
14. **`null as NonNull` throws at runtime** in sound null safety — don't use it
    to satisfy a non-nullable LSP handler return; register the method directly
    on the peer to return a real `null`.

### Dart craft

15. **Sealed event types + exhaustive `switch`** make a clean, future-proof
    component event API.
16. **Extract imperative UI's "brain" into a VM-testable module**
    (`designer_logic.dart`) — the DOM layer is browser-only, but its pure logic
    (validation, key derivation, model transforms) can and should run headlessly
    in `dart test`.
17. **`dart format` is authoritative; `--fatal-infos` is strict.**
    `prefer_const_constructors` is the most common info to chase — design
    const-constructible factories deliberately.
18. **Pub workspaces (`resolution: workspace`)** are native and sufficient for a
    monorepo — no melos needed for resolution (melos only adds orchestration
    scripts).

> **Skill shape.** A "jaspr-component" skill would encode: the two-barrel
> (VM-pure + `web.dart`) split as the *default* scaffold; the client-mode
> root-fill rule; the `<canvas>`-via-`Component.element` recipe; the
> build-daemon fallback; and the `package:web` string/`JSAny` cheat-sheet
> above. That's ~18 hard-won rules; most were discovered reactively here.

---

## 2. Should the harness become a Codex plugin/extension?

**Short answer: mostly no — leave the Makefile + AGENTS.md as the portable
contract, and invest editor-integration effort in the LSP instead.**

The harness today = `Makefile` + `tool/{verify,test,lint-ribbon,doctor}.sh` +
`AGENTS.md`. What it does well: one entry point (`make verify` =
format-check + analyze + test), project-specific validation (`make lint-ribbon`
via the LSP CLI), environment diagnostics (`make doctor`), and doc gen
(`make docs`). It is CI-friendly and language-agnostic in shape.

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Wrap the harness as a Codex CLI/app plugin** | Auto-run `make verify` after edits; surface `make doctor` as context; file-watch `.ribbon` → `lint-ribbon` | Reduces portability (Codex-only) for marginal gain; agents *already* follow `AGENTS.md` conventions | **Skip** |
| **Publish the `.ribbon` LSP as the editor extension** | Real, high-value editor integration (diagnostics/completion/hover); the VS Code scaffold already exists; works in any LSP-capable editor | Needs `npm`/`vsce` to package; one-time effort | **Do it** |
| **A thin Codex "skill"/instructions file pointing at `make verify` + the LSP** | Cheap; discoverable | It's basically more `AGENTS.md`, not a plugin | **Optional** |

**Why not the plugin:** agentic tools (Codex, Claude Code, etc.) auto-detect
build/test commands from `AGENTS.md`/`CLAUDE.md`. A Makefile target is the
*most portable* expression of "how to verify this repo" — wrapping it in a
vendor-specific plugin throws away that portability for a thin automation layer
the agent already provides. The one piece that genuinely benefits from being
*inside the editor* (not the agent) is the **language server**: it gives live
diagnostics/completion while a human types in VS Code, which no CLI agent
delivers. That's where extension effort pays off — and the LSP is already built
and smoke-tested.

**Recommendation:** (1) keep `make verify` + `AGENTS.md` as the cross-tool
contract; (2) ship the LSP as the real editor extension (the `editors/vscode/`
scaffold is 90% done — it just needs `npm install && vsce package`); (3) skip a
dedicated Codex plugin unless you later want Codex-specific UX (e.g. a
"validate current `.ribbon`" command button), in which case a *tiny* skill file
referencing the existing targets is enough — not a full plugin.

---

## 3. Plan vs. actual — how well we planned

### What went right

- **The milestone plan (M1–M5) held up.** All five shipped, in order, each
  verified green before moving on. Upfront decomposition from the Xojo source
  (`DEV_PLAN.md`, `LESSONS_LEARNED.md`, the Explorer JSON catalogue) was the
  correct first move — it grounded the port in real behaviour rather than
  guesswork.
- **The pure-Dart model + JSON serializer foundation paid off repeatedly.** The
  LSP server, the designer, and the tests all reuse one source of truth.
  Investing a whole milestone (M1) in the model before any rendering was the
  right sequencing.
- **The harness (`make verify`) caught regressions reliably** at every step
  (format, analyze, 223 assertions) — it was the safety net that made fast
  iteration safe.
- **Incremental, screenshot-verified delivery** kept the work honest: every
  milestone ended with a vision-confirmed render, not a "compiles = done."

### What we missed (planning gaps)

- **Imperative event-state subtleties.** The split-button dropdown "didn't
  work" because `pressedOnArrow` was reset before `_activate` read it. State
  machines that span press→release need explicit preservation; the plan didn't
  flag this.
- **Rebuild-on-keystroke focus loss** in the designer — a classic React-style
  mistake. Required an unplanned "quiet refresh" (update model + preview, skip
  inspector DOM) vs. "structural refresh" split.
- **Jaspr client-mode layout** (the floating footer). Root-must-fill-body is a
  client-mode-specific gotcha that no plan anticipated.
- **`package:web` interop friction.** The VM-pure-barrel boundary was discovered
  *reactively* (tests broke on `JSAny`), and `String`-vs-`JSAny` for DOM props
  caused a long tail of small fixes. The plan was optimistic about how clean the
  browser layer would be.
- **Build/environment yak-shaving.** The Jaspr daemon failure, the
  script-tag stripping, and `dart doc`-from-root each cost real time and were
  nowhere in the plan.

### Scope drift (honest)

- **Icon persistence evolved mid-project:** "iconKey only" → "embed data URLs
  in the `.ribbon` bundle." A genuine improvement, but a change to the schema
  after M1 had "finalised" it.
- **The `.zip` sidecar export was started** (the `archive` dependency was added
  to the designer) **but never finished** — it got deprioritised when the
  favicon and tutorial work landed. The dependency is still in the designer
  `pubspec.yaml`, unused. *(Loose end — see below.)*
- **M5 (LSP) API quirks** (`Hover` non-nullable return, `Either2` content
  changes, `TextDocumentContentChangeEvent` as a union) weren't anticipated —
  each needed on-the-fly API discovery against `lsp_server`.

### The catches that bit us

1. **Dropdown menu re-architected twice.** DOM overlay → user said "it renders
   outside the canvas, reconsider" → canvas-rendered overlay. The first design
   wasn't wrong, but it didn't match the user's mental model of "everything is
   the canvas."
2. **A screenshot that lied.** Forcing the menu open programmatically produced a
   green screenshot, masking the real click-path bug. Lesson: verify the *user
   path*, not just the render path.
3. **`null as Hover` throws** at runtime despite compiling — sound-null-safety
   casts to non-nullable aren't no-ops. Caused a silent LSP crash until caught.
4. **Vision-tool flakiness** during verification (timeouts/GOAWAY) forced
   fallbacks to DOM-dumps and pixel sampling (e.g. confirming the footer was
   flush by reading the bottom scanline). A useful resilience pattern.
5. **A mid-project "plan mode" interlude** (read-only) interrupted flow and
   required re-confirmation to resume — an operational constraint, not a
   technical one.

### Planning grade: **B+**

Strong structure and sequencing; weak on estimating (a) Jaspr/Dart interop
friction, (b) imperative-event-state subtleties, and (c) environment
yak-shaving. The plan was optimistic about "how clean the port would be" and
light on "how fiddly the browser + build pipeline is." A more honest plan would
have budgeted a dedicated "interop/build-hardening" spike before M2.

---

## Loose ends / future work

- **`archive` dep unused** in `apps/jaspr_ribbon_designer/pubspec.yaml` — remove
  it, or finish the `.zip` sidecar export it was added for.
- **Icon-bundle format choice:** icons are embedded as data URLs in the JSON
  bundle (self-contained but verbose). A `.zip` (loose SVG/PNG files +
  `ribbon.json`) remains an unimplemented alternative for version-control-friendly bundles.
- **Designer has no end-to-end (browser) test** — only its pure logic is tested
  (`designer_logic_test.dart`). A `jaspr_test`/chrome smoke test would close the
  gap.
- **LSP `Hover`/completion are crude** (line-based context detection). A proper
  JSON AST/position-aware analysis would be more accurate.
- **Publishing:** the package is path-dependency only; `pub.dev` publish +
  a versioned VS Code `.vsix` are the gates to "1.0".

---

## TL;DR

- **For a Jaspr-component skill:** encode the VM-pure/`web.dart` split, the
  client-mode root-fill rule, `<canvas>` via `Component.element`, the
  build-daemon fallback, and the `package:web` string/`JSAny` cheat-sheet.
- **For the harness:** keep it a portable Makefile + `AGENTS.md`; spend
  editor-integration budget on the **LSP**, not a Codex plugin.
- **On planning:** good bones (M1–M5 held), but we underestimated interop,
  imperative state, and build friction — and learned that a screenshot can lie
  if you don't verify the real user path.
