/// The five core item-type constants, mirroring Xojo's
/// `XjRibbonItem` `kItemType*` constants (0–4).
///
/// Higher-level `.ribbon` JSON `"itemType"` strings — `"large"`, `"small"`,
/// `"dropdown"`, `"splitbutton"`, `"toggle"`, `"checkbox"`, `"separator"` — are
/// decomposed by [RibbonItem.fromJson] into a [RibbonItemType] plus the
/// `isToggle` / `isSplitButton` flags. This matches the Xojo key decisions:
///
///  - `IsSplitButton` is a flag on `ItemType = dropdown` (not a new type).
///  - `kItemTypeCheckBox` (3) reuses `IsToggleActive` for checked state.
///  - `toggle` is a `large`/`small` item with `isToggle = true`.
enum RibbonItemType {
  /// 32px icon + caption below; spans full group height. (`kItemTypeLarge = 0`)
  large,

  /// 16px icon + caption to the right; stacks three-per-column. (`kItemTypeSmall = 1`)
  small,

  /// Large icon + caption + chevron; whole-button menu OR split (see `isSplitButton`). (`kItemTypeDropdown = 2`)
  dropdown,

  /// ☐/☑ glyph + caption row; reuses `isToggleActive` for checked state. (`kItemTypeCheckBox = 3`)
  checkBox,

  /// A non-interactive column boundary inside a group. (`kItemTypeSeparator = 4`)
  separator;

  /// `true` for [separator], which renders nothing and has no hit area.
  bool get isNonInteractive => this == RibbonItemType.separator;

  /// The human-readable `.ribbon` JSON token this type maps to when no flags
  /// are set. Flag-bearing variants (`"splitbutton"`, `"toggle"`) are handled
  /// by [RibbonItem.jsonType].
  String get defaultJsonType => switch (this) {
    RibbonItemType.large => 'large',
    RibbonItemType.small => 'small',
    RibbonItemType.dropdown => 'dropdown',
    RibbonItemType.checkBox => 'checkbox',
    RibbonItemType.separator => 'separator',
  };
}
