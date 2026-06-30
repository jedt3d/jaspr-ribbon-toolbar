import 'ribbon_group.dart';
import 'ribbon_item.dart';

/// A top-level tab of the ribbon. Counterpart of Xojo's `XjRibbonTab`.
///
/// Tabs are either standard (`isContextual = false`) or contextual. A
/// contextual tab belongs to a named context group (e.g. `"Table Tools"`) and
/// is shown/hidden as a unit; it also carries an [accentColor] (ARGB int).
class RibbonTab {
  /// Standard tab.
  const RibbonTab({required this.caption, required this.groups, this.keyTip})
    : isContextual = false,
      contextGroup = null,
      accentColor = null;

  /// Contextual tab, shown only while its [contextGroup] is active.
  const RibbonTab.contextual({
    required this.caption,
    required this.groups,
    required this.contextGroup,
    this.accentColor,
    this.keyTip,
  }) : isContextual = true;

  /// Human-readable tab label.
  final String caption;

  /// Controls in this tab, grouped.
  final List<RibbonGroup> groups;

  /// `true` if this tab only appears for a specific context.
  final bool isContextual;

  /// Context group name (e.g. `"Table Tools"`), only for contextual tabs.
  final String? contextGroup;

  /// ARGB accent colour for contextual tabs; `null` means default.
  final int? accentColor;

  /// Optional manual KeyTip badge.
  final String? keyTip;

  /// Parses a `.ribbon` JSON tab object.
  factory RibbonTab.fromJson(Map<String, dynamic> json) {
    final caption = (json['caption'] as String?) ?? '';
    final groups = (json['groups'] as List<dynamic>? ?? const [])
        .map((e) => RibbonGroup.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final isContextual = (json['isContextual'] as bool?) ?? false;
    final keyTip = json['keyTip'] as String?;

    if (isContextual) {
      return RibbonTab.contextual(
        caption: caption,
        groups: groups,
        contextGroup: (json['contextGroup'] as String?) ?? '',
        accentColor: json['accentColor'] as int?,
        keyTip: keyTip,
      );
    }
    return RibbonTab(caption: caption, groups: groups, keyTip: keyTip);
  }

  /// Serializes this tab to the `.ribbon` JSON shape.
  Map<String, dynamic> toJson() => {
    'caption': caption,
    if (isContextual) 'isContextual': true,
    if (isContextual && contextGroup != null) 'contextGroup': contextGroup,
    if (accentColor != null) 'accentColor': accentColor,
    if (keyTip != null) 'keyTip': keyTip,
    'groups': groups.map((g) => g.toJson()).toList(growable: false),
  };

  /// Finds the item whose [RibbonItem.tag] equals [tag] anywhere in this tab.
  RibbonItem? findItem(String tag) {
    for (final group in groups) {
      final found = group.findItem(tag);
      if (found != null) return found;
    }
    return null;
  }

  RibbonTab copyWith({
    String? caption,
    List<RibbonGroup>? groups,
    String? keyTip,
  }) => isContextual
      ? RibbonTab.contextual(
          caption: caption ?? this.caption,
          groups: groups ?? this.groups,
          contextGroup: contextGroup,
          accentColor: accentColor,
          keyTip: keyTip ?? this.keyTip,
        )
      : RibbonTab(
          caption: caption ?? this.caption,
          groups: groups ?? this.groups,
          keyTip: keyTip ?? this.keyTip,
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RibbonTab &&
          other.caption == caption &&
          other.isContextual == isContextual &&
          other.contextGroup == contextGroup &&
          other.accentColor == accentColor &&
          other.keyTip == keyTip &&
          _listEquals(other.groups, groups);

  @override
  int get hashCode => Object.hash(
    caption,
    isContextual,
    contextGroup,
    accentColor,
    keyTip,
    Object.hashAll(groups),
  );

  @override
  String toString() => 'RibbonTab($caption, ${groups.length} groups)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
