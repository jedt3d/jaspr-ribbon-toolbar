import 'package:jaspr_ribbon_lsp/jaspr_ribbon_lsp.dart';
import 'package:test/test.dart';

void main() {
  group('detectFieldContext', () {
    test('detects itemType', () {
      expect(
        detectFieldContext('"itemType": "lar"', 17),
        FieldContext.itemType,
      );
      expect(detectFieldContext('  "itemType": "', 15), FieldContext.itemType);
    });

    test('detects iconKey', () {
      expect(detectFieldContext('"iconKey": "pa"', 15), FieldContext.iconKey);
    });

    test('returns other for unrelated lines', () {
      expect(detectFieldContext('"caption": "Paste"', 12), FieldContext.other);
      expect(detectFieldContext('', 0), FieldContext.other);
    });
  });

  group('completion suggestions', () {
    test('itemType returns the 7 tokens', () {
      expect(
        suggestItemTypes(),
        containsAll([
          'large',
          'small',
          'dropdown',
          'splitbutton',
          'toggle',
          'checkbox',
          'separator',
        ]),
      );
    });

    test('iconKey collects item keys + bundle icons', () {
      const source = '''
{
  "version": "2.0", "projectType": "web",
  "tabs": [{ "caption": "H", "groups": [{ "caption": "G", "items": [
    { "caption": "Paste", "tag": "p", "itemType": "large", "iconKey": "paste" }
  ]}]}],
  "icons": { "paste": { "kind": "svg", "data": "x" }, "copy": { "kind": "png", "data": "y" } }
}
''';
      final keys = suggestIconKeys(source);
      expect(keys, containsAll(['paste', 'copy']));
    });

    test('iconKey returns empty on invalid JSON', () {
      expect(suggestIconKeys('{ broken'), isEmpty);
    });
  });

  group('hover docs', () {
    test('known token returns a description', () {
      expect(itemTypeDoc('splitbutton'), contains('Split button'));
      expect(itemTypeDoc('checkbox'), contains('kItemTypeCheckBox'));
    });

    test('unknown token returns null', () {
      expect(itemTypeDoc('nope'), isNull);
    });
  });

  group('wordAt', () {
    test('extracts a dotted token under the cursor', () {
      expect(wordAt('clipboard.paste', 11), 'clipboard.paste');
      expect(wordAt('"itemType": "splitbutton"', 21), 'splitbutton');
    });
  });
}
