import 'package:jaspr_ribbon_designer/designer_logic.dart';
import 'package:jaspr_ribbon_toolbar/model.dart';
import 'package:test/test.dart';

/// VM unit tests for the designer's pure logic (the imperative DOM layer is
/// browser-only; these cover its "brain" — validation, key derivation, model
/// transforms — so `make verify` exercises the designer behaviour headlessly).
void main() {
  group('sanitizeKey', () {
    test('lowercases and strips non-[a-z.]', () {
      expect(sanitizeKey('Copy Path'), 'copypath');
      expect(sanitizeKey('Bold (B)'), 'boldb');
      expect(sanitizeKey('a.b.c'), 'a.b.c');
      expect(sanitizeKey('ICON_1'), 'icon');
    });
  });

  group('uniqueIconKey', () {
    test('returns base when free', () {
      expect(uniqueIconKey('paste', ['cut', 'copy']), 'paste');
    });
    test('appends .1/.2 on collision', () {
      expect(uniqueIconKey('paste', ['paste']), 'paste.1');
      expect(uniqueIconKey('paste', ['paste', 'paste.1']), 'paste.2');
    });
  });

  group('deriveIconKey', () {
    test('drops extension, lowercases, separator→dot', () {
      expect(deriveIconKey('paste.svg'), 'paste');
      expect(deriveIconKey('Copy Path.svg'), 'copy.path');
      expect(deriveIconKey('ICON_1.png'), 'icon');
    });
    test('falls back to icon when empty', () {
      expect(deriveIconKey('...svg'), 'icon');
    });
  });

  group('rebuildItemAs', () {
    final source = RibbonItem.large(
      caption: 'X',
      tag: 'x',
      iconKey: 'i',
      tooltipText: 'tip',
      menuItems: const [RibbonMenuItem(caption: 'M', tag: 'm')],
    );

    test('separator ignores all fields', () {
      expect(rebuildItemAs(source, 'separator').isSeparator, isTrue);
    });

    test('dropdown keeps menu items', () {
      final d = rebuildItemAs(source, 'dropdown');
      expect(d.itemType, RibbonItemType.dropdown);
      expect(d.menuItems, hasLength(1));
      expect(d.iconKey, 'i');
    });

    test('toggle preserves active state as isActive', () {
      final on = source.copyWith(isToggle: true, isToggleActive: true);
      final t = rebuildItemAs(on, 'toggle');
      expect(t.isToggle, isTrue);
      expect(t.isToggleActive, isTrue);
    });

    test('checkbox maps active→checked', () {
      final c = rebuildItemAs(
        source.copyWith(isToggle: true, isToggleActive: true),
        'checkbox',
      );
      expect(c.itemType, RibbonItemType.checkBox);
      expect(c.isToggleActive, isTrue);
    });

    test('splitbutton keeps menu items + flag', () {
      final s = rebuildItemAs(source, 'splitbutton');
      expect(s.isSplitButton, isTrue);
      expect(s.menuItems, hasLength(1));
    });
  });

  group('rebuildTab', () {
    const tab = RibbonTab(
      caption: 'Home',
      groups: [RibbonGroup(caption: 'G', items: [])],
    );

    test('toggles contextual on with default group', () {
      final ctx = rebuildTab(tab, isContextual: true);
      expect(ctx.isContextual, isTrue);
      expect(ctx.contextGroup, 'New context');
      expect(ctx.groups, hasLength(1));
    });

    test('toggles contextual off (drops context fields)', () {
      final ctx = rebuildTab(
        tab,
        isContextual: true,
        contextGroup: 'Picture Tools',
        accentColor: 0xFF2E7D32,
      );
      final back = rebuildTab(ctx, isContextual: false);
      expect(back.isContextual, isFalse);
      expect(back.contextGroup, isNull);
    });
  });

  group('retargetIcon', () {
    test('updates every item referencing the old key', () {
      final model = RibbonDefinition(
        tabs: [
          RibbonTab(
            caption: 'Home',
            groups: [
              RibbonGroup(
                caption: 'G',
                items: [
                  RibbonItem.large(caption: 'A', tag: 'a', iconKey: 'paste'),
                  RibbonItem.small(caption: 'B', tag: 'b', iconKey: 'copy'),
                  RibbonItem.small(caption: 'C', tag: 'c', iconKey: 'paste'),
                ],
              ),
            ],
          ),
        ],
      );
      final retargeted = retargetIcon(model, 'paste', 'paste.renamed');
      final keys = retargeted.tabs.first.groups.first.items
          .map((i) => i.iconKey)
          .toList();
      expect(keys, ['paste.renamed', 'copy', 'paste.renamed']);
    });
  });
}
