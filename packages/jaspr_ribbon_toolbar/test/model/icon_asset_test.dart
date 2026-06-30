import 'package:jaspr_ribbon_toolbar/model.dart';
import 'package:test/test.dart';

void main() {
  group('RibbonDefinition.icons', () {
    test('are empty by default and omitted from JSON', () {
      const def = RibbonDefinition(tabs: []);
      expect(def.icons, isEmpty);
      expect(def.toJson().containsKey('icons'), isFalse);
    });

    test('round-trip through JSON', () {
      final def = RibbonDefinition(
        version: '2.0',
        projectType: 'web',
        tabs: [
          RibbonTab(
            caption: 'Home',
            groups: [
              RibbonGroup(
                caption: 'G',
                items: [
                  RibbonItem.large(
                    caption: 'Paste',
                    tag: 'p',
                    iconKey: 'paste',
                  ),
                ],
              ),
            ],
          ),
        ],
        icons: {
          'paste': const IconAsset(
            kind: IconAssetKind.svg,
            data: 'data:image/svg+xml;base64,QUJD',
          ),
          'pic': const IconAsset(
            kind: IconAssetKind.png,
            data: 'data:image/png;base64,aGVsbG8=',
          ),
        },
      );
      final json = def.toJsonString();
      final restored = RibbonDefinition.fromJsonString(json);
      expect(restored, def);
      expect(restored.icons['paste']?.kind, IconAssetKind.svg);
      expect(restored.icons['pic']?.data, 'data:image/png;base64,aGVsbG8=');
    });

    test('kind is inferred when missing from JSON', () {
      final asset = IconAsset.fromJson({'data': 'icons/foo.svg'});
      expect(asset.kind, IconAssetKind.svg);
      final png = IconAsset.fromJson({'data': 'data:image/png;base64,AA=='});
      expect(png.kind, IconAssetKind.png);
    });

    test('unknown icons shape is tolerated (treated as empty)', () {
      const def = RibbonDefinition(tabs: []);
      final restored = RibbonDefinition.fromJson({
        ...def.toJson(),
        'icons': 'not-a-map',
      });
      expect(restored.icons, isEmpty);
    });
  });
}
