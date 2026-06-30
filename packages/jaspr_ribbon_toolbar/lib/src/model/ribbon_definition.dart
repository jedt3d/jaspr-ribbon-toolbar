import 'dart:convert';

import 'icon_asset.dart';
import 'ribbon_item.dart';
import 'ribbon_tab.dart';

/// The root of a ribbon definition: the in-memory counterpart of a `.ribbon`
/// JSON bundle. Shared verbatim by the canvas renderer, the visual designer,
/// and the LSP server.
///
/// Schema version is `"2.0"` (the Xojo designer's final schema, extended with
/// `splitbutton`, `toggle`, `checkbox`). For Jaspr the [projectType] is always
/// `"web"`. An optional [icons] map embeds SVG/PNG assets so a saved bundle is
/// self-contained.
class RibbonDefinition {
  const RibbonDefinition({
    this.version = kSchemaVersion,
    this.projectType = kProjectTypeWeb,
    required this.tabs,
    this.icons = const {},
  });

  /// Current `.ribbon` schema version.
  static const String kSchemaVersion = '2.0';

  /// Project type used for Jaspr targets.
  static const String kProjectTypeWeb = 'web';

  /// Schema version (`"2.0"`).
  final String version;

  /// Rendering target — `"web"` for Jaspr.
  final String projectType;

  /// Ordered tabs (standard first, contextual last by convention).
  final List<RibbonTab> tabs;

  /// Optional embedded icon assets (iconKey → [IconAsset]). Lets a saved
  /// `.ribbon` bundle carry its own SVG/PNG data URLs.
  final Map<String, IconAsset> icons;

  /// Parses a `.ribbon` JSON object.
  factory RibbonDefinition.fromJson(Map<String, dynamic> json) {
    final iconsRaw = json['icons'];
    final icons = <String, IconAsset>{};
    if (iconsRaw is Map<String, dynamic>) {
      for (final entry in iconsRaw.entries) {
        if (entry.value is Map<String, dynamic>) {
          icons[entry.key] = IconAsset.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }
    return RibbonDefinition(
      version: (json['version'] as String?) ?? kSchemaVersion,
      projectType: (json['projectType'] as String?) ?? kProjectTypeWeb,
      tabs: (json['tabs'] as List<dynamic>? ?? const [])
          .map((e) => RibbonTab.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      icons: icons,
    );
  }

  /// Parses a `.ribbon` JSON document from a string.
  factory RibbonDefinition.fromJsonString(String source) =>
      RibbonDefinition.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Serializes this definition to a `.ribbon` JSON object.
  Map<String, dynamic> toJson() => {
    'version': version,
    'projectType': projectType,
    'tabs': tabs.map((t) => t.toJson()).toList(growable: false),
    if (icons.isNotEmpty)
      'icons': {for (final e in icons.entries) e.key: e.value.toJson()},
  };

  /// Serializes this definition to a pretty-printed `.ribbon` JSON string.
  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson()) + '\n';

  /// Standard (non-contextual) tabs.
  Iterable<RibbonTab> get standardTabs => tabs.where((t) => !t.isContextual);

  /// Contextual tabs only.
  Iterable<RibbonTab> get contextualTabs => tabs.where((t) => t.isContextual);

  /// Contextual tabs belonging to [contextGroup].
  Iterable<RibbonTab> contextualTabsFor(String contextGroup) =>
      tabs.where((t) => t.isContextual && t.contextGroup == contextGroup);

  /// Finds the item with [tag] anywhere in the definition.
  RibbonItem? findItem(String tag) {
    for (final tab in tabs) {
      final found = tab.findItem(tag);
      if (found != null) return found;
    }
    return null;
  }

  /// Whether every toggle/checkbox item tag exists.
  bool containsTag(String tag) => findItem(tag) != null;

  /// Current toggle/checkbox state of the item with [tag], or `false` if absent.
  bool isToggleActive(String tag) => findItem(tag)?.isToggleActive ?? false;

  /// Returns a copy with the toggle state of [tag] flipped. Returns `this`
  /// unchanged if [tag] is unknown or the item is not a toggle.
  RibbonDefinition toggled(String tag) {
    for (var ti = 0; ti < tabs.length; ti++) {
      final tab = tabs[ti];
      for (var gi = 0; gi < tab.groups.length; gi++) {
        final group = tab.groups[gi];
        for (var ii = 0; ii < group.items.length; ii++) {
          final item = group.items[ii];
          if (item.tag == tag && item.isToggling) {
            final newTabs = List<RibbonTab>.of(tabs);
            final newGroups = List.of(tab.groups);
            final newItems = List.of(group.items);
            newItems[ii] = item.toggled();
            newGroups[gi] = group.copyWith(items: newItems);
            newTabs[ti] = tab.copyWith(groups: newGroups);
            return RibbonDefinition(
              version: version,
              projectType: projectType,
              tabs: newTabs,
              icons: icons,
            );
          }
        }
      }
    }
    return this;
  }

  RibbonDefinition copyWith({
    String? version,
    String? projectType,
    List<RibbonTab>? tabs,
    Map<String, IconAsset>? icons,
  }) => RibbonDefinition(
    version: version ?? this.version,
    projectType: projectType ?? this.projectType,
    tabs: tabs ?? this.tabs,
    icons: icons ?? this.icons,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RibbonDefinition &&
          other.version == version &&
          other.projectType == projectType &&
          _listEquals(other.tabs, tabs) &&
          _mapEquals(other.icons, icons);

  @override
  int get hashCode => Object.hash(
    version,
    projectType,
    Object.hashAll(tabs),
    Object.hashAllUnordered(icons.entries),
  );

  @override
  String toString() =>
      'RibbonDefinition(v$version, $projectType, ${tabs.length} tabs)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
