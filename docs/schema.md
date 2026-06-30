# The `.ribbon` JSON schema (v2.0)

The `.ribbon` format is the shared contract between the renderer, the visual
designer, and the LSP server. It descends directly from the Xojo `XjRibbon`
designer's schema (see `XjRibbon-main/DEV_PLAN.md` §"Designer .ribbon Schema").

## Top level

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `version` | string | yes | — | Must be `"2.0"`. |
| `projectType` | string | yes | — | Always `"web"` for Jaspr. (Xojo used `"desktop"`/`"web"`.) |
| `tabs` | array | yes | — | Ordered tabs; standard first, contextual last by convention. |

## Tab

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `caption` | string | yes | Tab label. |
| `groups` | array | yes | Groups in this tab. |
| `isContextual` | bool | no | `true` for a contextual tab. |
| `contextGroup` | string | contextual only | e.g. `"Table Tools"`, `"Picture Tools"`. |
| `accentColor` | int | no | ARGB accent for contextual tabs. |
| `keyTip` | string | no | Manual KeyTip badge (desktop nav; unused on web). |

## Group

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `caption` | string | yes | Centred label below the controls. |
| `items` | array | yes | Ordered items. |

## Item

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `itemType` | string | yes | One of the seven tokens below. |
| `caption` | string | non-separator | Human-readable label. |
| `tag` | string | non-separator | Stable identifier dispatched in events. |
| `iconKey` | string | no | Key into the `IconRegistry`. |
| `tooltipText` | string | no | Native tooltip. |
| `isEnabled` | bool | no | `true` by default. |
| `isToggleActive` | bool | toggle/checkbox | Current active/checked state. |
| `keyTip` | string | no | Manual KeyTip badge. |
| `menuItems` | array | dropdown/splitbutton | Popup entries (see below). |

### The seven `itemType` tokens

| Token | Xojo origin | Behaviour |
|-------|-------------|-----------|
| `large` | `kItemTypeLarge = 0` | 32px icon + caption below; spans group height. |
| `small` | `kItemTypeSmall = 1` | 16px icon + caption right; stacks 3-per-column. |
| `dropdown` | `kItemTypeDropdown = 2` | Any click opens `menuItems`. |
| `splitbutton` | `IsSplitButton = True` | Body click fires `ItemPressed`; arrow click opens `menuItems`. |
| `toggle` | `IsToggle` on large | Press-hold toggle; no glyph; toggles `isToggleActive`. |
| `checkbox` | `kItemTypeCheckBox = 3` | ☐/☑ glyph + text row; toggles `isToggleActive`. |
| `separator` | `kItemTypeSeparator = 4` | Non-interactive column boundary inside a group. |

## Menu item

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `caption` | string | yes | Label. |
| `tag` | string | yes | Dispatched as `DropdownMenuActionEvent.menuItemTag`. |

A menu separator is `{"itemType": "separator"}`.

## Validation

Validate any bundle from the CLI:

```bash
make lint-ribbon FILE=path/to/x.ribbon
```

The strict validator (`packages/jaspr_ribbon_lsp/lib/src/ribbon_validator.dart`)
reports: invalid JSON (with line:column), missing `version`/`tabs`/`caption`/
`tag`, unknown `itemType`, contextual tabs without `contextGroup`, and dropdowns
without `menuItems`.

## Full example

See [`examples/explorer.ribbon`](../examples/explorer.ribbon) — a faithful slice
of the Windows File Explorer Home/View tabs exercising every control kind,
including a contextual "Format" (Picture Tools) tab.
