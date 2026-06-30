# Tutorial 3 — A real-life change request

**Goal:** see what a product change looks like end-to-end on a shipped app — the
**visual** part done in the designer, the **behaviour** part done in code — and
internalise the project's core workflow.

> **The lesson this tutorial teaches:** *structural and visual* changes (tabs,
> buttons, captions, icons) are **no-code** — re-skin in the designer, save the
> `.ribbon` bundle, drop it back into `web/assets/`. Only *behaviour* changes
> (what a click does) touch your Dart.

---

## The scenario

You shipped the app from Tutorials 1–2. It has a ribbon with **Home** and
**View** tabs, a dark **Copy** button, and a **Hidden items** checkbox that only
logs. A ticket lands:

> **CR-1042 — Ribbon updates**
> 1. Add an **Insert** tab with a **Table** button.
> 2. **Hidden items** must actually toggle "show hidden files" and refresh the
>    list (currently it does nothing).
> 3. The ribbon should **follow the page colour scheme** (it's stuck in light).
> 4. Rename **Copy** → **Copy file** and give it the tag `clipboard.copy.file`
>    (so analytics can distinguish it from future "Copy path").

Notice the split: #1 and #4 (structure/caption/tag) and the *icon* are visual;
#2 and #3 are behaviour. Let's do them in that order.

---

## Part A — Visual changes (in the designer, no Dart)

### A.1 Open the live bundle

```bash
cd apps/jaspr_ribbon_designer && jaspr serve
```

Click **Load** and pick the app's `web/assets/ribbon.bundle.json`. The
structure, inspector, and icon gallery populate from the bundle (icons are
embedded, so they come back too).

### A.2 Add the "Insert" tab + "Table" button

1. **Add → Tab**. Select it, set **Caption** = `Insert`.
2. With `Insert` selected, **Add → Group** → **Caption** = `Table`.
3. With `Table` selected, **Add → Large button** → **Caption** = `Table`,
   **Tag** = `insert.table`.
4. (Optional) **Upload** a table SVG in the Icons pane and click it to assign —
   the live preview shows the glyph.

### A.3 Rename "Copy" → "Copy file" + new tag

In the tree, select the `Copy` item. In the Inspector:

- **Caption**: `Copy` → `Copy file`
- **Tag**: `clipboard.copy` → `clipboard.copy.file` (the field enforces
  `[a-z.]`)

### A.4 Confirm the "Hidden items" checkbox

Select the View tab's **Show/hide** group; confirm the **Hidden items** checkbox
exists with **Tag** = `view.hidden` (it does from Tutorial 1). No visual change
needed here — the behaviour work is in Part B.

### A.5 Save and replace the bundle

**Save .ribbon** → copy the downloaded `ribbon.bundle.json` over
`my_app/web/assets/ribbon.bundle.json`.

Reload the app: the **Insert** tab, **Table** button, the renamed **Copy file**,
and the new icon all appear — **without recompiling a line of Dart**, because
the app loads the bundle at runtime via `fetch`.

> The only thing now broken: clicking **Table** does nothing (its tag isn't in
> the command map yet), and **Copy**'s old handler is orphaned. That's Part B.

---

## Part B — Behaviour changes (in code)

Recall the command map and handler from Tutorial 2.

### B.1 Update the command map (CR #1 + #4)

`lib/main.client.dart` — before:

```dart
final _commands = <String, void Function()>{
  'clipboard.paste': paste,
  'clipboard.cut': cut,
  'clipboard.copy': copy,                 // ← old tag, old name
  'organize.delete.recycle': recycle,
  'organize.delete.permanent': deletePermanently,
};
```

After:

```dart
final _commands = <String, void Function()>{
  'clipboard.paste': paste,
  'clipboard.cut': cut,
  'clipboard.copy.file': copyFile,        // ← renamed tag (CR #4)
  'organize.delete.recycle': recycle,
  'organize.delete.permanent': deletePermanently,
  'insert.table': insertTable,            // ← new (CR #1)
};

void insertTable() => showInsertDialog('table');
void copyFile() => clipboard.copy(currentSelection());
```

Because `onCommand(tag)` is `_commands[tag]?.call()`, that's all the wiring the
new button needs.

### B.2 Make "Hidden items" actually work (CR #2)

The controller already flips the checkbox and dispatches `ItemPressedEvent`;
you just read the new state and apply it. In the `ItemPressed` switch:

```dart
case ItemPressedEvent(:final tag):
  switch (tag) {
    case 'view.hidden':
      final showHidden = _ribbon!.getToggleState('view.hidden'); // fresh value
      appSettings.showHiddenFiles = showHidden;
      refreshFileList();                  // re-render with/without hidden entries
    case 'font.bold':
      applyToggle('font.bold');
    // …
    default:
      _commands[tag]?.call();
  }
```

Need to set it from elsewhere too (e.g. a menu elsewhere toggles the setting)?

```dart
_ribbon?.setToggleState('view.hidden', appSettings.showHiddenFiles);
```

### B.3 Follow the page colour scheme (CR #3)

Wire the controller's dark-mode palette to the browser's `prefers-color-scheme`,
reacting to live changes. In `attachRibbon()`, after `..attach()`:

```dart
final mql = web.window.matchMedia('(prefers-color-scheme: dark)');
_ribbon!.setDarkMode(mql.matches);
mql.addEventListener(
  'change',
  ((web.Event _) => _ribbon?.setDarkMode(mql.matches)).toJS,
);
```

Now flipping the OS theme (or a page-level dark class that flips the media
query) re-paints the ribbon in the ported dark palette instantly.

---

## Part C — Verify

```bash
jaspr serve
```

Checklist against the ticket:

- ✅ **Insert** tab with a working **Table** button (dialog opens).
- ✅ **Copy file** (renamed) fires `clipboard.copy.file`; old `clipboard.copy`
  is harmlessly absent from the map.
- ✅ **Hidden items** toggles `showHiddenFiles` and the list refreshes.
- ✅ Ribbon follows the colour scheme.

---

## What changed where

| Change | Where it was made | Recompile? |
|--------|-------------------|------------|
| Insert tab, Table button, icon | Designer → `ribbon.bundle.json` | No (runtime `fetch`) |
| Rename Copy → Copy file + new tag | Designer → bundle | No |
| `insert.table` / `clipboard.copy.file` handlers | `main.client.dart` command map | Yes |
| Hidden items drives app state | `main.client.dart` event switch | Yes |
| Dark-mode sync | `main.client.dart` `matchMedia` | Yes |

That's the workflow in one table: **designer for the eyes, Dart for the hands.**
Non-coders can ship most ribbon changes; engineers focus on behaviour.

---

## Where to go next

- [`docs/schema.md`](../docs/schema.md) — the full `.ribbon` field reference.
- [`docs/porting-from-xojo.md`](../docs/porting-from-xojo.md) — Xojo → Dart map.
- [`packages/jaspr_ribbon_lsp/README.md`](../packages/jaspr_ribbon_lsp/README.md)
  — editor autocomplete/validation for `.ribbon` files.
- `AGENTS.md` — architecture, conventions, and the milestone history.
