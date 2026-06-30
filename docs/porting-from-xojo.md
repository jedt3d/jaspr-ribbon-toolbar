# Porting from Xojo XjRibbon to Dart/Jaspr

This guide maps every concept in the Xojo `XjRibbon` library to its counterpart
in this package. Use it as a Rosetta stone when porting behaviour or comparing
tests.

## Project structure

| Xojo (`XjRibbon-main/`) | Dart (`jaspr-ribbon-toolbar/`) |
|--------------------------|--------------------------------|
| `desktop/XjRibbon.xojo_code` (canvas + renderer) | `packages/jaspr_ribbon_toolbar/lib/src/components/ribbon_toolbar.dart` + `RibbonPainter` *(M2)* |
| `desktop/XjRibbonTab.xojo_code` | `lib/src/model/ribbon_tab.dart` |
| `desktop/XjRibbonGroup.xojo_code` | `lib/src/model/ribbon_group.dart` |
| `desktop/XjRibbonItem.xojo_code` | `lib/src/model/ribbon_item.dart` |
| (menu items live on `XjRibbonItem`) | `lib/src/model/menu_item.dart` |
| (rendering helpers) | `lib/src/theme/ribbon_colors.dart` |
| `designer/` | `apps/jaspr_ribbon_designer/` *(planned, M4)* |

## Item type constants

| Xojo constant | Xojo value | `.ribbon` token | Dart `RibbonItemType` | Dart factory |
|---------------|-----------|-----------------|----------------------|--------------|
| `kItemTypeLarge` | 0 | `large` | `.large` | `RibbonItem.large` |
| `kItemTypeSmall` | 1 | `small` | `.small` | `RibbonItem.small` |
| `kItemTypeDropdown` | 2 | `dropdown` / `splitbutton` | `.dropdown` | `RibbonItem.dropdown` / `.splitButton` |
| `kItemTypeCheckBox` | 3 | `checkbox` | `.checkBox` | `RibbonItem.checkBox` |
| `kItemTypeSeparator` | 4 | `separator` | `.separator` | `RibbonItem.separator` |
| (flag `IsToggle` on 0/1) | — | `toggle` | `.large` + `isToggle` | `RibbonItem.toggle` |
| (flag `IsSplitButton` on 2) | — | `splitbutton` | `.dropdown` + `isSplitButton` | `RibbonItem.splitButton` |

## Group factory methods → Dart constructors

| Xojo | Dart |
|------|------|
| `group.AddLargeButton(caption, tag)` | `RibbonItem.large(caption: , tag: )` |
| `group.AddSmallButton(caption, tag)` | `RibbonItem.small(...)` |
| `group.AddDropdownButton(caption, tag)` | `RibbonItem.dropdown(...)` |
| `group.AddSplitButton(caption, tag)` | `RibbonItem.splitButton(...)` |
| `group.AddCheckBox(caption, tag, initial)` | `RibbonItem.checkBox(isChecked: )` |
| `group.AddSeparator()` | `RibbonItem.separator()` |
| `item.AddMenuItem(caption, tag)` | pass `menuItems: [RibbonMenuItem(...)]` |

## Item properties

| Xojo property | Dart field |
|---------------|-----------|
| `item.Caption` | `item.caption` |
| `item.Tag` | `item.tag` |
| `item.Icon` (Picture — the pain point) | `item.iconKey` (string → `IconRegistry`) |
| `item.TooltipText` | `item.tooltipText` |
| `item.IsEnabled` | `item.isEnabled` |
| `item.IsToggle` | `item.isToggle` |
| `item.IsToggleActive` | `item.isToggleActive` |
| `item.IsSplitButton` | `item.isSplitButton` |
| `item.KeyTip` | `item.keyTip` |

## Global state & queries

| Xojo | Dart |
|------|------|
| `XjRibbon.AddTab(caption)` | `RibbonTab(caption: , groups: )` in `RibbonDefinition.tabs` |
| `XjRibbon.AddContextualTab(...)` | `RibbonTab.contextual(contextGroup: , accentColor: )` |
| `XjRibbon.SetCollapsed(v)` / `IsCollapsed()` | `RibbonToolbar(collapsed: )` prop *(M3)* |
| `XjRibbon.GetToggleState(tag)` | `definition.isToggleActive(tag)` |
| `XjRibbon.SetToggleState(tag, v)` | `definition.copyWith(...)` / `definition.toggled(tag)` |
| `XjRibbon.Clear()` | build a new `RibbonDefinition` (immutable) |

## Events

| Xojo event | Dart event class |
|------------|------------------|
| `ItemPressed(tag)` | `ItemPressedEvent(tag)` |
| `DropdownMenuAction(itemTag, menuItemTag)` | `DropdownMenuActionEvent{itemTag, menuItemTag}` |
| `CollapseStateChanged(isCollapsed)` | `CollapseStateChangedEvent(isCollapsed)` |
| (implicit tab switch) | `TabChangedEvent(tabIndex)` |

Switch over `RibbonEvent` exhaustively (it is `sealed`).

## Rendering notes (M2)

The Xojo `Paint`/`LayoutTabs`/`HitTestItems` logic ports to a Dart
`RibbonPainter` driving the Canvas 2D context. Translation table:

| Xojo Graphics call | Canvas 2D call |
|--------------------|----------------|
| `g.DrawPicture(pic, x, y, w, h)` | `ctx.drawImage(img, x, y, w, h)` |
| `g.FillRoundRectangle(x,y,w,h,cw)` | `ctx.beginPath(); ctx.roundRect(x,y,w,h,r); ctx.fill();` |
| `g.DrawString(s, x, y)` | `ctx.fillText(s, x, y)` |
| `g.TextWidth(s)` | `ctx.measureText(s).width` *(no `Picture.Graphics` workaround needed!)* |
| `g.Transparency = 60` | `ctx.globalAlpha = 0.4` |

Xojo web constraints (no `TextWidth`, no `Transparency`, single-param
`FillRoundRectangle`, 120% scaling) **do not apply** — the Canvas 2D API has all
of these natively.

## Layout constants to port

From `desktop/XjRibbon.xojo_code` (verify against source before M2):

- Large icon: 32px. Small icon: 16px.
- Small/checkbox items stack 3-per-column.
- SplitButton body/arrow split at 80%/20% of button width.
- Group caption centred below controls; vertical dividers between groups.
- Active-tab blue underline; hover/pressed backgrounds from `RibbonColors`.

## Gotchas that DON'T carry over

See `LESSONS_LEARNED.md` in the Xojo repo — the Xojo-specific traps (WebCanvas
missing MouseMove, `Session.HashtagChanged` signature, file-copy reverts, etc.)
are irrelevant in Dart. Only the **decisions** carry over (see
[`AGENTS.md` §6](../AGENTS.md)).
