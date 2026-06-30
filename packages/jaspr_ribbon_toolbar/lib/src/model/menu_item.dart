/// An entry inside a dropdown or split-button's popup menu.
///
/// Mirrors Xojo `XjRibbonItem.AddMenuItem(caption, tag)`. A menu may also
/// contain separators (`{"itemType": "separator"}` / `{"type": "Separator"}`).
class RibbonMenuItem {
  /// Creates an actionable menu entry.
  const RibbonMenuItem({required this.caption, required this.tag})
    : isSeparator = false;

  /// Creates a non-interactive separator line inside a menu.
  const RibbonMenuItem.separator() : caption = '', tag = '', isSeparator = true;

  /// Human-readable label shown in the popup menu.
  final String caption;

  /// Stable identifier dispatched by [DropdownMenuActionEvent.menuItemTag].
  final String tag;

  /// `true` for a separator entry.
  final bool isSeparator;

  /// Parses a `.ribbon` JSON menu entry. Both the library schema
  /// (`{"caption", "tag"}`) and the reference catalogue
  /// (`{"id","label","type"}`) shapes are accepted.
  factory RibbonMenuItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? json['itemType'];
    if (type == 'Separator' || type == 'separator') {
      return const RibbonMenuItem.separator();
    }
    final caption = (json['caption'] ?? json['label'] ?? '').toString();
    final tag = (json['tag'] ?? json['id'] ?? '').toString();
    return RibbonMenuItem(caption: caption, tag: tag);
  }

  /// Serializes this entry to the `.ribbon` JSON shape.
  Map<String, dynamic> toJson() {
    if (isSeparator) {
      return {'itemType': 'separator'};
    }
    return {'caption': caption, 'tag': tag};
  }

  RibbonMenuItem copyWith({String? caption, String? tag}) {
    if (isSeparator) return this;
    return RibbonMenuItem(
      caption: caption ?? this.caption,
      tag: tag ?? this.tag,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RibbonMenuItem &&
      other.isSeparator == isSeparator &&
      other.caption == caption &&
      other.tag == tag;

  @override
  int get hashCode => Object.hash(isSeparator, caption, tag);

  @override
  String toString() => isSeparator
      ? 'RibbonMenuItem.separator()'
      : 'RibbonMenuItem($caption → $tag)';
}
