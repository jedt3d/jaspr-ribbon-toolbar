# Tutorial 2 — Events, toggles & contextual tabs

**Goal:** turn the `handleEvent` stub from Tutorial 1 into real behaviour —
respond to button clicks and dropdown picks, read and set toggle/checkbox
state, reveal contextual tabs, and sync dark mode.

The `RibbonCanvasController` you attached in Tutorial 1 is your handle to all of
this. Below, `_ribbon` is that controller:

```dart
RibbonCanvasController? _ribbon;
```

---

## 1. The event model

`RibbonEvent` is a **sealed** type — `switch` over it and the compiler guarantees
you've covered every case. There are four:

| Event | Fired when | Key fields |
|-------|------------|------------|
| `ItemPressedEvent` | A button, toggle, or checkbox is activated; **also** the body of a split button. | `tag` |
| `DropdownMenuActionEvent` | A menu item is chosen from a dropdown / split-button's popup. | `itemTag`, `menuItemTag` |
| `CollapseStateChangedEvent` | The user clicks the collapse chevron (or double-clicks a tab). | `isCollapsed` |
| `TabChangedEvent` | The active tab changes. | `tabIndex`, optional `contextGroup` |

A typical dispatcher:

```dart
void handleEvent(RibbonEvent e) {
  switch (e) {
    case ItemPressedEvent(:final tag):
      onCommand(tag);
    case DropdownMenuActionEvent(:final itemTag, :final menuItemTag):
      onCommand(menuItemTag);          // the leaf action is the menu item's tag
    case CollapseStateChangedEvent(:final isCollapsed):
      onRibbonCollapsed(isCollapsed);
    case TabChangedEvent(:final tabIndex):
      onTabChanged(tabIndex);
  }
}
```

> **Tags are your contract.** Each control carries a `tag` (e.g.
> `clipboard.paste`, `font.bold`). Treat tags as a command enum and route them
> through a central map — that keeps UI and logic decoupled.

---

## 2. Buttons and dropdown menus

Plain buttons and the **body** of split buttons fire `ItemPressedEvent`.
Choosing an entry from a dropdown or split-button's ▾ menu fires
`DropdownMenuActionEvent` whose `menuItemTag` is the chosen menu item's tag.

```dart
final _commands = <String, void Function()>{
  'clipboard.paste': paste,
  'clipboard.cut': cut,
  'clipboard.copy': copy,
  // split button 'Delete' → body fires 'organize.delete' (ItemPressed);
  // its ▾ menu items fire these:
  'organize.delete.recycle': recycle,
  'organize.delete.permanent': deletePermanently,
};

void onCommand(String tag) => _commands[tag]?.call();
```

So the **Delete** split button gives you two behaviours for free: click the body
→ `organize.delete` (e.g. "delete with last-used mode"); click the ▾ → choose
`Recycle` / `Permanently delete`.

You can also **open a menu programmatically** (e.g. from a keyboard shortcut):

```dart
_ribbon?.openMenuForTag('organize.delete');
```

---

## 3. Toggle and checkbox state

Toggles (`RibbonItem.toggle`) and checkboxes (`RibbonItem.checkBox`) keep an
on/off state. When the user clicks one, the controller **flips the state and
then** dispatches `ItemPressedEvent(tag)`. Read the new value with
`getToggleState`:

```dart
void onCommand(String tag) {
  switch (tag) {
    case 'font.bold':
      // The controller has already toggled it; read the fresh value:
      final isBold = _ribbon!.getToggleState('font.bold');
      document.execCommand('bold'); // or set your editor's state
      updateUi('font.bold', isBold);
    case 'font.italic':
      final isItalic = _ribbon!.getToggleState('font.italic');
      document.execCommand('italic');
      updateUi('font.italic', isItalic);
    default:
      _commands[tag]?.call();
  }
}
```

**Set state from code** (e.g. reflect an external change) — the controller
updates the model and re-paints:

```dart
// user pressed Ctrl+B somewhere else — sync the ribbon:
_ribbon?.setToggleState('font.bold', true);
```

| You want to… | Call |
|--------------|------|
| Read a toggle/checkbox | `_ribbon.getToggleState('font.bold')` |
| Set a toggle/checkbox | `_ribbon.setToggleState('font.bold', true)` |

---

## 4. Contextual tabs

Contextual tabs (e.g. a **Format** tab that only appears while a picture is
selected) are hidden until you reveal their **context group**. Design one in the
designer: select a tab → tick **Contextual tab** → set **Context group** (e.g.
`Picture Tools`) and an accent colour.

At runtime, show/hide the whole group:

```dart
// User selected a picture → reveal the Format tab:
_ribbon?.showContextGroup('Picture Tools');

// User clicked away → hide it (the active tab auto-falls back to a standard tab):
_ribbon?.hideContextGroup('Picture Tools');

// Or toggle and read the result:
final nowVisible = _ribbon?.toggleContextGroup('Picture Tools') ?? false;
```

When the user activates a contextual tab you'll get a `TabChangedEvent`; its
optional `contextGroup` tells you which context is now active.

---

## 5. Programmatic tab + collapse + dark mode

```dart
_ribbon?.setActiveTab(2);                 // switch to the 3rd tab
_ribbon?.setDefinition(newDefinition);    // hot-swap the whole ribbon (used by the designer)
_ribbon?.setIcons(newRegistry);           // swap the icon set
```

Collapse is user-driven via the chevron (and fires `CollapseStateChangedEvent`).
React to it (e.g. to reposition page content):

```dart
void onRibbonCollapsed(bool collapsed) {
  // e.g. toggle a CSS class on the layout below:
  (web.document.getElementById('stage') as web.HTMLElement)
      .style
      .display = collapsed ? 'none' : 'block';
}
```

**Dark mode** — swap the ported palette at runtime:

```dart
// one-shot:
_ribbon?.setDarkMode(true);

// follow the OS / page scheme:
bool dark = web.window.matchMedia('(prefers-color-scheme: dark)').matches;
_ribbon?.setDarkMode(dark);
```

You can also pass a custom palette: `_ribbon?.setColors(myRibbonColors)`.

---

## 6. Putting it together

A compact, production-shaped handler:

```dart
void handleEvent(RibbonEvent e) {
  switch (e) {
    case ItemPressedEvent(:final tag):
      switch (tag) {
        case 'font.bold':
          applyToggle('font.bold');
        case 'font.italic':
          applyToggle('font.italic');
        case 'view.preview':
          // a toggle that drives a panel
          setPreviewPane(_ribbon!.getToggleState('view.preview'));
        default:
          _commands[tag]?.call();
      }
    case DropdownMenuActionEvent(:final menuItemTag):
      _commands[menuItemTag]?.call();
    case CollapseStateChangedEvent(:final isCollapsed):
      layout.collapsed = isCollapsed;
    case TabChangedEvent(:final tabIndex, :final contextGroup):
      if (contextGroup == 'Picture Tools') pictureToolsActivated();
      analytics.track('ribbon_tab', tabIndex);
  }
}

void applyToggle(String tag) {
  final on = _ribbon!.getToggleState(tag);
  // apply `on` to your model/editor, then:
  updateUi(tag, on);
}
```

That's the full event surface: buttons, dropdowns, toggles, contextual tabs,
collapse, and dark mode.

Next: **[Tutorial 3 — a real-life change request](03-change-request-scenario.md)**
shows what a product change looks like end-to-end.
