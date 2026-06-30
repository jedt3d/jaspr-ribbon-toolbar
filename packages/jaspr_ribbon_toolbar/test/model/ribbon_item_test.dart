import 'package:jaspr_ribbon_toolbar/model.dart';
import 'package:test/test.dart';

void main() {
  group('RibbonItem factories', () {
    test('large has the expected shape', () {
      final item = RibbonItem.large(
        caption: 'Paste',
        tag: 'clipboard.paste',
        iconKey: 'paste',
      );
      expect(item.itemType, RibbonItemType.large);
      expect(item.jsonType, 'large');
      expect(item.isToggle, isFalse);
      expect(item.isSplitButton, isFalse);
      expect(item.isInteractive, isTrue);
      expect(item.isSeparator, isFalse);
    });

    test('dropdown vs splitButton differ only by the split flag', () {
      final drop = RibbonItem.dropdown(caption: 'Sort', tag: 'sort');
      final split = RibbonItem.splitButton(caption: 'Delete', tag: 'delete');
      expect(drop.itemType, RibbonItemType.dropdown);
      expect(split.itemType, RibbonItemType.dropdown);
      expect(drop.isSplitButton, isFalse);
      expect(split.isSplitButton, isTrue);
      expect(drop.jsonType, 'dropdown');
      expect(split.jsonType, 'splitbutton');
    });

    test('toggle and checkBox are both toggling but distinct jsonTypes', () {
      final toggle = RibbonItem.toggle(
        caption: 'Preview pane',
        tag: 'view.preview',
        isActive: true,
      );
      final checkbox = RibbonItem.checkBox(
        caption: 'Hidden items',
        tag: 'view.hidden',
        isChecked: true,
      );
      expect(toggle.isToggle && checkbox.isToggle, isTrue);
      expect(toggle.isToggling && checkbox.isToggling, isTrue);
      expect(toggle.isToggleActive, isTrue);
      expect(checkbox.isToggleActive, isTrue);
      expect(toggle.jsonType, 'toggle');
      expect(checkbox.jsonType, 'checkbox');
      expect(checkbox.itemType, RibbonItemType.checkBox);
    });

    test('separator is non-interactive and const', () {
      const item = RibbonItem.separator();
      expect(item.itemType, RibbonItemType.separator);
      expect(item.isInteractive, isFalse);
      expect(item.jsonType, 'separator');
      expect(item.isSeparator, isTrue);
    });

    test('toggled() flips the active state', () {
      final item = RibbonItem.checkBox(
        caption: 'c',
        tag: 't',
        isChecked: false,
      );
      expect(item.toggled().isToggleActive, isTrue);
      expect(item.toggled().toggled().isToggleActive, isFalse);
    });
  });

  group('RibbonItem JSON round-trip', () {
    final cases = <String, RibbonItem>{
      'large': RibbonItem.large(
        caption: 'Paste',
        tag: 'clipboard.paste',
        tooltipText: 'Paste',
        iconKey: 'paste',
      ),
      'small': RibbonItem.small(caption: 'Copy', tag: 'clipboard.copy'),
      'dropdown': RibbonItem.dropdown(
        caption: 'Sort by',
        tag: 'view.sort',
        menuItems: const [
          RibbonMenuItem(caption: 'Name', tag: 'name'),
          RibbonMenuItem.separator(),
        ],
      ),
      'splitbutton': RibbonItem.splitButton(
        caption: 'Delete',
        tag: 'edit.delete',
      ),
      'toggle': RibbonItem.toggle(
        caption: 'Preview pane',
        tag: 'view.preview',
        isActive: true,
      ),
      'checkbox': RibbonItem.checkBox(
        caption: 'Hidden items',
        tag: 'view.hidden',
        isChecked: true,
      ),
      'separator': const RibbonItem.separator(),
    };

    for (final entry in cases.entries) {
      test('${entry.key} survives toJson -> fromJson', () {
        final round = RibbonItem.fromJson(entry.value.toJson());
        expect(round, entry.value);
        expect(round.jsonType, entry.value.jsonType);
      });
    }
  });

  group('RibbonMenuItem', () {
    test('parses both library and reference catalogue shapes', () {
      expect(
        RibbonMenuItem.fromJson({'caption': 'Name', 'tag': 'name'}).tag,
        'name',
      );
      expect(
        RibbonMenuItem.fromJson({'label': 'Name', 'id': 'name'}).tag,
        'name',
      );
      expect(
        RibbonMenuItem.fromJson({'type': 'Separator'}).isSeparator,
        isTrue,
      );
      expect(
        RibbonMenuItem.fromJson({'itemType': 'separator'}).isSeparator,
        isTrue,
      );
    });
  });
}
