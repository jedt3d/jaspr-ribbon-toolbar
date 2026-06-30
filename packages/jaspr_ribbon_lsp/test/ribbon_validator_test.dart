import 'package:jaspr_ribbon_lsp/jaspr_ribbon_lsp.dart';
import 'package:test/test.dart';

void main() {
  group('validateRibbonSource', () {
    test('accepts a well-formed document', () {
      const source = '''
{
  "version": "2.0",
  "projectType": "web",
  "tabs": [
    {
      "caption": "Home",
      "groups": [
        {
          "caption": "Clipboard",
          "items": [
            { "caption": "Paste", "tag": "paste", "itemType": "large" }
          ]
        }
      ]
    }
  ]
}
''';
      expect(validateRibbonSource(source), isEmpty);
    });

    test('reports invalid JSON with a line:column', () {
      final diags = validateRibbonSource('{ not json');
      expect(diags, hasLength(1));
      expect(diags.first.severity, RibbonSeverity.error);
      expect(diags.first.message, contains('Invalid JSON'));
    });

    test('flags an unknown itemType', () {
      const source = '''
{"version":"2.0","tabs":[{"caption":"H","groups":[{"caption":"G","items":[
  {"caption":"X","tag":"x","itemType":"hyperbutton"}
]}]}]}
''';
      final diags = validateRibbonSource(source);
      expect(diags, isNotEmpty);
      expect(diags.any((d) => d.message.contains('hyperbutton')), isTrue);
    });

    test('warns when a dropdown has no menu items', () {
      const source = '''
{"version":"2.0","tabs":[{"caption":"H","groups":[{"caption":"G","items":[
  {"caption":"Sort","tag":"sort","itemType":"dropdown"}
]}]}]}
''';
      final diags = validateRibbonSource(source);
      expect(diags.any((d) => d.message.contains('menuItems')), isTrue);
    });

    test('warns on unsupported schema version', () {
      const source = '{"version":"1.0","tabs":[]}';
      final diags = validateRibbonSource(source);
      expect(
        diags.any((d) => d.message.contains('Unsupported schema version')),
        isTrue,
      );
    });

    test('contextual tab without contextGroup is a warning', () {
      const source = '''
{"version":"2.0","tabs":[{"caption":"F","isContextual":true,"groups":[]}]}
''';
      final diags = validateRibbonSource(source);
      expect(diags.any((d) => d.message.contains('contextGroup')), isTrue);
    });
  });
}
