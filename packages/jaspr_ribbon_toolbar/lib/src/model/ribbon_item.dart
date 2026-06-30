import 'item_type.dart';
import 'menu_item.dart';

/// A single control inside a [RibbonGroup].
///
/// This is the Dart counterpart of Xojo's `XjRibbonItem`. The seven control
/// kinds visible in the Windows File Explorer reference (see
/// `image ref/explorer_ribbon_toolbar.json`) are expressed as a combination of
/// [itemType] with the [isToggle], [isSplitButton] and [isToggleActive] flags —
/// exactly the decomposition the Xojo library settled on:
///
/// | `.ribbon` itemType  | itemType          | isToggle | isSplitButton |
/// |---------------------|-------------------|----------|---------------|
/// | `large`             | [RibbonItemType.large]    | false | false |
/// | `small`             | [RibbonItemType.small]    | false | false |
/// | `dropdown`          | [RibbonItemType.dropdown] | false | false |
/// | `splitbutton`       | [RibbonItemType.dropdown] | false | true  |
/// | `toggle`            | [RibbonItemType.large]    | true  | false |
/// | `checkbox`          | [RibbonItemType.checkBox] | true  | false |
/// | `separator`         | [RibbonItemType.separator] | —     | —     |
///
/// **Icons.** Unlike Xojo (where wiring `Picture` objects was the documented
/// pain point), icons here are referenced by a string [iconKey] that resolves
/// against an `IconRegistry` of SVG/PNG assets. This makes the model pure data
/// — serializable, diffable, and usable by the LSP server and designer.
class RibbonItem {
  /// Creates a fully-specified item. Prefer the named factories.
  const RibbonItem({
    required this.caption,
    required this.tag,
    required this.itemType,
    this.isEnabled = true,
    this.isToggle = false,
    this.isToggleActive = false,
    this.isSplitButton = false,
    this.tooltipText,
    this.iconKey,
    this.keyTip,
    this.menuItems = const [],
  });

  /// Large button: 32px icon + caption below.
  factory RibbonItem.large({
    required String caption,
    required String tag,
    String? tooltipText,
    String? iconKey,
    String? keyTip,
    bool isEnabled = true,
    List<RibbonMenuItem> menuItems = const [],
  }) {
    return RibbonItem(
      caption: caption,
      tag: tag,
      itemType: RibbonItemType.large,
      tooltipText: tooltipText,
      iconKey: iconKey,
      keyTip: keyTip,
      isEnabled: isEnabled,
      menuItems: menuItems,
    );
  }

  /// Small button: 16px icon + caption to the right; stacks three-per-column.
  factory RibbonItem.small({
    required String caption,
    required String tag,
    String? tooltipText,
    String? iconKey,
    String? keyTip,
    bool isEnabled = true,
  }) {
    return RibbonItem(
      caption: caption,
      tag: tag,
      itemType: RibbonItemType.small,
      tooltipText: tooltipText,
      iconKey: iconKey,
      keyTip: keyTip,
      isEnabled: isEnabled,
    );
  }

  /// Dropdown button: any click opens the popup [menuItems].
  factory RibbonItem.dropdown({
    required String caption,
    required String tag,
    String? tooltipText,
    String? iconKey,
    String? keyTip,
    bool isEnabled = true,
    List<RibbonMenuItem> menuItems = const [],
  }) {
    return RibbonItem(
      caption: caption,
      tag: tag,
      itemType: RibbonItemType.dropdown,
      tooltipText: tooltipText,
      iconKey: iconKey,
      keyTip: keyTip,
      isEnabled: isEnabled,
      menuItems: menuItems,
    );
  }

  /// Split button: body click fires [ItemPressedEvent], arrow click opens
  /// [menuItems] → [DropdownMenuActionEvent]. (Xojo `IsSplitButton = True`.)
  factory RibbonItem.splitButton({
    required String caption,
    required String tag,
    String? tooltipText,
    String? iconKey,
    String? keyTip,
    bool isEnabled = true,
    List<RibbonMenuItem> menuItems = const [],
  }) {
    return RibbonItem(
      caption: caption,
      tag: tag,
      itemType: RibbonItemType.dropdown,
      isSplitButton: true,
      tooltipText: tooltipText,
      iconKey: iconKey,
      keyTip: keyTip,
      isEnabled: isEnabled,
      menuItems: menuItems,
    );
  }

  /// Toggle button: retains pressed/unpressed state (e.g. Preview pane).
  factory RibbonItem.toggle({
    required String caption,
    required String tag,
    bool isActive = false,
    String? tooltipText,
    String? iconKey,
    String? keyTip,
    bool isEnabled = true,
  }) {
    return RibbonItem(
      caption: caption,
      tag: tag,
      itemType: RibbonItemType.large,
      isToggle: true,
      isToggleActive: isActive,
      tooltipText: tooltipText,
      iconKey: iconKey,
      keyTip: keyTip,
      isEnabled: isEnabled,
    );
  }

  /// Check box: ☐/☑ glyph + caption row; [isActive] is the checked state.
  factory RibbonItem.checkBox({
    required String caption,
    required String tag,
    bool isChecked = false,
    String? tooltipText,
    String? keyTip,
    bool isEnabled = true,
  }) {
    return RibbonItem(
      caption: caption,
      tag: tag,
      itemType: RibbonItemType.checkBox,
      isToggle: true,
      isToggleActive: isChecked,
      tooltipText: tooltipText,
      keyTip: keyTip,
      isEnabled: isEnabled,
    );
  }

  /// Separator: a non-interactive column boundary inside a group.
  const factory RibbonItem.separator() = _SeparatorItem;

  /// Human-readable label.
  final String caption;

  /// Stable identifier dispatched in events.
  final String tag;

  /// Core control category.
  final RibbonItemType itemType;

  /// Whether the control is clickable. Separators ignore this.
  final bool isEnabled;

  /// Turns a large/small button into a press-hold toggle.
  final bool isToggle;

  /// Current state of a [isToggle] / check-box item.
  final bool isToggleActive;

  /// `ItemType = dropdown` with two hit areas (body + arrow).
  final bool isSplitButton;

  /// Native tooltip text.
  final String? tooltipText;

  /// Key into an `IconRegistry` (SVG or PNG). Solves the Xojo icon pain point.
  final String? iconKey;

  /// Optional manual KeyTip badge (keyboard navigation).
  final String? keyTip;

  /// Popup entries for dropdown / split items.
  final List<RibbonMenuItem> menuItems;

  /// `true` for separators.
  bool get isSeparator => itemType == RibbonItemType.separator;

  /// `true` if this item participates in hit-testing / events.
  bool get isInteractive => !itemType.isNonInteractive;

  /// Whether a click should toggle [isToggleActive].
  bool get isToggling => isToggle && !isSplitButton;

  /// The `.ribbon` JSON `"itemType"` token that round-trips this item.
  String get jsonType {
    if (isSeparator) return 'separator';
    if (isSplitButton) return 'splitbutton';
    if (itemType == RibbonItemType.checkBox) return 'checkbox';
    if (isToggle) return 'toggle';
    return itemType.defaultJsonType;
  }

  /// Parses a `.ribbon` JSON item object.
  factory RibbonItem.fromJson(Map<String, dynamic> json) {
    final rawType = (json['itemType'] as String?)?.toLowerCase() ?? 'large';

    if (rawType == 'separator') {
      return const RibbonItem.separator();
    }

    final caption = (json['caption'] as String?) ?? '';
    final tag = (json['tag'] as String?) ?? '';
    final isEnabled = (json['isEnabled'] as bool?) ?? true;
    final tooltipText = json['tooltipText'] as String?;
    final iconKey = (json['iconKey'] as String?) ?? (json['icon'] as String?);
    final keyTip = json['keyTip'] as String?;
    final isToggleActive = (json['isToggleActive'] as bool?) ?? false;

    final menuRaw = json['menuItems'] as List<dynamic>?;
    final menuItems =
        menuRaw
            ?.map((e) => RibbonMenuItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <RibbonMenuItem>[];

    switch (rawType) {
      case 'small':
        return RibbonItem.small(
          caption: caption,
          tag: tag,
          tooltipText: tooltipText,
          iconKey: iconKey,
          keyTip: keyTip,
          isEnabled: isEnabled,
        );
      case 'dropdown':
        return RibbonItem.dropdown(
          caption: caption,
          tag: tag,
          tooltipText: tooltipText,
          iconKey: iconKey,
          keyTip: keyTip,
          isEnabled: isEnabled,
          menuItems: menuItems,
        );
      case 'splitbutton':
        return RibbonItem.splitButton(
          caption: caption,
          tag: tag,
          tooltipText: tooltipText,
          iconKey: iconKey,
          keyTip: keyTip,
          isEnabled: isEnabled,
          menuItems: menuItems,
        );
      case 'toggle':
        return RibbonItem.toggle(
          caption: caption,
          tag: tag,
          isActive: isToggleActive,
          tooltipText: tooltipText,
          iconKey: iconKey,
          keyTip: keyTip,
          isEnabled: isEnabled,
        );
      case 'checkbox':
        return RibbonItem.checkBox(
          caption: caption,
          tag: tag,
          isChecked: isToggleActive,
          tooltipText: tooltipText,
          keyTip: keyTip,
          isEnabled: isEnabled,
        );
      case 'large':
      default:
        return RibbonItem.large(
          caption: caption,
          tag: tag,
          tooltipText: tooltipText,
          iconKey: iconKey,
          keyTip: keyTip,
          isEnabled: isEnabled,
          menuItems: menuItems,
        );
    }
  }

  /// Serializes this item to the `.ribbon` JSON shape.
  Map<String, dynamic> toJson() {
    if (isSeparator) {
      return {'itemType': 'separator'};
    }
    return {
      'caption': caption,
      'tag': tag,
      'itemType': jsonType,
      'isEnabled': isEnabled,
      if (isToggle) 'isToggleActive': isToggleActive,
      if (tooltipText != null) 'tooltipText': tooltipText,
      if (iconKey != null) 'iconKey': iconKey,
      if (keyTip != null) 'keyTip': keyTip,
      if (menuItems.isNotEmpty)
        'menuItems': menuItems.map((m) => m.toJson()).toList(),
    };
  }

  /// Returns a copy with the given fields replaced.
  RibbonItem copyWith({
    String? caption,
    String? tag,
    RibbonItemType? itemType,
    bool? isEnabled,
    bool? isToggle,
    bool? isToggleActive,
    bool? isSplitButton,
    Object? tooltipText = _sentinel,
    Object? iconKey = _sentinel,
    Object? keyTip = _sentinel,
    List<RibbonMenuItem>? menuItems,
  }) {
    if (isSeparator) return this;
    return RibbonItem(
      caption: caption ?? this.caption,
      tag: tag ?? this.tag,
      itemType: itemType ?? this.itemType,
      isEnabled: isEnabled ?? this.isEnabled,
      isToggle: isToggle ?? this.isToggle,
      isToggleActive: isToggleActive ?? this.isToggleActive,
      isSplitButton: isSplitButton ?? this.isSplitButton,
      tooltipText: identical(tooltipText, _sentinel)
          ? this.tooltipText
          : tooltipText as String?,
      iconKey: identical(iconKey, _sentinel)
          ? this.iconKey
          : iconKey as String?,
      keyTip: identical(keyTip, _sentinel) ? this.keyTip : keyTip as String?,
      menuItems: menuItems ?? this.menuItems,
    );
  }

  /// Returns the item with [isToggleActive] flipped (toggle / check-box click).
  RibbonItem toggled() => copyWith(isToggleActive: !isToggleActive);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RibbonItem &&
          other.caption == caption &&
          other.tag == tag &&
          other.itemType == itemType &&
          other.isEnabled == isEnabled &&
          other.isToggle == isToggle &&
          other.isToggleActive == isToggleActive &&
          other.isSplitButton == isSplitButton &&
          other.tooltipText == tooltipText &&
          other.iconKey == iconKey &&
          other.keyTip == keyTip &&
          _listEquals(other.menuItems, menuItems);

  @override
  int get hashCode => Object.hash(
    caption,
    tag,
    itemType,
    isEnabled,
    isToggle,
    isToggleActive,
    isSplitButton,
    tooltipText,
    iconKey,
    keyTip,
    Object.hashAll(menuItems),
  );

  @override
  String toString() => 'RibbonItem($caption → $tag, $jsonType)';
}

const Object _sentinel = Object();

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Private redirecting target so [RibbonItem.separator] can be `const`.
class _SeparatorItem extends RibbonItem {
  const _SeparatorItem()
    : super(
        caption: '',
        tag: '',
        itemType: RibbonItemType.separator,
        isEnabled: false,
      );
}
