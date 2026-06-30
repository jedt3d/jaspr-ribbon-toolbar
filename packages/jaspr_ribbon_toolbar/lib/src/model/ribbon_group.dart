import 'ribbon_item.dart';

/// A labeled cluster of controls inside a [RibbonTab], separated from
/// neighbouring groups by a vertical divider.
///
/// Counterpart of Xojo's `XjRibbonGroup`. A group owns an ordered list of
/// [RibbonItem]s; the layout engine flows small/checkbox items in three-deep
/// columns and uses separators as column boundaries.
class RibbonGroup {
  const RibbonGroup({required this.caption, required this.items});

  /// Human-readable label rendered centred below the group's controls.
  final String caption;

  /// Ordered controls in this group.
  final List<RibbonItem> items;

  /// Parses a `.ribbon` JSON group object.
  factory RibbonGroup.fromJson(Map<String, dynamic> json) {
    return RibbonGroup(
      caption: (json['caption'] as String?) ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => RibbonItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Serializes this group to the `.ribbon` JSON shape.
  Map<String, dynamic> toJson() => {
    'caption': caption,
    'items': items.map((i) => i.toJson()).toList(growable: false),
  };

  /// All non-separator items in this group.
  Iterable<RibbonItem> get interactive => items.where((i) => i.isInteractive);

  /// Finds the item whose [RibbonItem.tag] equals [tag], if any.
  RibbonItem? findItem(String tag) {
    for (final item in items) {
      if (item.tag == tag) return item;
    }
    return null;
  }

  RibbonGroup copyWith({String? caption, List<RibbonItem>? items}) =>
      RibbonGroup(caption: caption ?? this.caption, items: items ?? this.items);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RibbonGroup &&
          other.caption == caption &&
          _listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(caption, Object.hashAll(items));

  @override
  String toString() => 'RibbonGroup($caption, ${items.length} items)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
