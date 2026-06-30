/// An icon asset embedded in a `.ribbon` bundle (the persistence counterpart of
/// the runtime `IconSource`/`IconRegistry`). Storing assets in the bundle makes
/// it self-contained — a saved `.ribbon` carries its own SVG/PNG data URLs.
class IconAsset {
  const IconAsset({required this.kind, required this.data});

  /// Whether [data] is SVG or PNG.
  final IconAssetKind kind;

  /// The asset payload — typically a `data:` URL (e.g. as produced by the
  /// designer's `FileReader.readAsDataURL`), but a plain URL/path is also
  /// accepted.
  final String data;

  /// Parses a bundle `icons` entry: `{"kind": "svg"|"png", "data": "..."}`.
  /// The `kind` is inferred from the data if omitted.
  factory IconAsset.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as String?) ?? '';
    final kind =
        IconAssetKind.parse(json['kind'] as String?) ??
        IconAssetKind.infer(data);
    return IconAsset(kind: kind, data: data);
  }

  /// Serializes this asset to the bundle shape.
  Map<String, dynamic> toJson() => {'kind': kind.name, 'data': data};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconAsset && other.kind == kind && other.data == data;

  @override
  int get hashCode => Object.hash(kind, data);

  @override
  String toString() => 'IconAsset(${kind.name}, ${data.length} chars)';
}

/// The two supported icon asset formats (mirrors the runtime `IconKind`).
enum IconAssetKind {
  svg,
  png;

  /// Parses a kind string; `null` if unrecognised.
  static IconAssetKind? parse(String? value) {
    switch (value) {
      case 'svg':
        return IconAssetKind.svg;
      case 'png':
        return IconAssetKind.png;
      default:
        return null;
    }
  }

  /// Infers the kind from a data URL / path / mime.
  static IconAssetKind infer(String data) {
    final lower = data.toLowerCase();
    if (lower.contains('image/svg') || lower.endsWith('.svg'))
      return IconAssetKind.svg;
    return IconAssetKind.png;
  }
}
