import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';
import 'package:test/test.dart';

void main() {
  group('RibbonColors', () {
    test('resolve returns the right palette per mode', () {
      expect(RibbonColors.resolve(isDarkMode: false), same(RibbonColors.light));
      expect(RibbonColors.resolve(isDarkMode: true), same(RibbonColors.dark));
    });

    test('toCssHex formats 6-digit hex', () {
      expect(RibbonColors.toCssHex(0xFF1A73E8), '#1a73e8');
      expect(RibbonColors.toCssHex(0xFF000000), '#000000');
    });

    test('toCssRgba honours the alpha channel', () {
      expect(RibbonColors.toCssRgba(0xFF1A73E8), 'rgba(26, 115, 232, 1.000)');
      expect(RibbonColors.toCssRgba(0x661A73E8), 'rgba(26, 115, 232, 0.400)');
    });
  });

  group('IconRegistry', () {
    test('lookup returns the registered source', () {
      final reg = IconRegistry.assets(const {
        'paste': IconSource.svg('<svg/>'),
        'copy': IconSource.png('iVBOR...'),
      });
      expect(reg['paste']?.kind, IconKind.svg);
      expect(reg['copy']?.kind, IconKind.png);
      expect(reg['missing'], isNull);
      expect(reg[null], isNull);
      expect(reg.containsKey('copy'), isTrue);
      expect(reg.length, 2);
    });

    test('merge favours the right-hand registry', () {
      final a = IconRegistry.assets(const {'x': IconSource.svg('a')});
      final b = IconRegistry.assets(const {
        'x': IconSource.svg('b'),
        'y': IconSource.svg('b'),
      });
      expect(a.merge(b)['x']?.data, 'b');
      expect(a.merge(b)['y']?.data, 'b');
    });
  });
}
