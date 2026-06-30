/// Resolves a [RibbonItem.iconKey] to a concrete icon asset.
///
/// This is the Dart solution to the icon pain point documented in the Xojo
/// project ("the complicated thing in Xojo is how to use SVG/PNG images as the
/// toolbar icons"). Instead of passing opaque `Picture` objects through the
/// model, items reference a string key; the renderer asks the registry for the
/// bytes/source at paint time.
///
/// registries are immutable value objects so definitions stay pure data and
/// diffable. Build one with [IconRegistry.assets] or merge several with
/// [IconRegistry.merge].
class IconRegistry {
  const IconRegistry._(this._entries);

  /// Empty registry (every lookup returns `null`).
  const IconRegistry.empty() : _entries = const {};

  /// Creates a registry from a `{key: source}` map. A [IconSource.kind] of
  /// [IconKind.svg] or [IconKind.png] selects the canvas draw strategy.
  factory IconRegistry.assets(Map<String, IconSource> entries) =>
      IconRegistry._(Map<String, IconSource>.unmodifiable(entries));

  final Map<String, IconSource> _entries;

  /// Looks up the asset registered for [key], or `null`.
  IconSource? operator [](String? key) => key == null ? null : _entries[key];

  /// Whether [key] is registered.
  bool containsKey(String key) => _entries.containsKey(key);

  /// All registered keys.
  Iterable<String> get keys => _entries.keys;

  /// Number of registered assets.
  int get length => _entries.length;

  /// Merges multiple registries; later registries win on key conflicts.
  IconRegistry merge(IconRegistry other) {
    return IconRegistry.assets({..._entries, ...other._entries});
  }
}

/// A single icon asset, either SVG or PNG.
class IconSource {
  const IconSource.svg(this.data) : kind = IconKind.svg;

  const IconSource.png(this.data) : kind = IconKind.png;

  /// Whether this asset is vector (SVG) or raster (PNG).
  final IconKind kind;

  /// Raw asset payload:
  ///  - SVG: the markup text.
  ///  - PNG: the base64-encoded image data (without the `data:` prefix).
  final String data;

  /// A web URL (e.g. `assets/icons/paste.svg`) usable directly as an `<img>` src
  /// or `Image.src`. Prefer this when shipping icons as static assets.
  static IconSource svgUrl(String url) => IconSource.svg(url);
  static IconSource pngUrl(String url) => IconSource.png(url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconSource && other.kind == kind && other.data == data;

  @override
  int get hashCode => Object.hash(kind, data);

  @override
  String toString() => 'IconSource($kind, ${data.length} chars)';
}

/// The two supported icon asset formats.
enum IconKind { svg, png }
