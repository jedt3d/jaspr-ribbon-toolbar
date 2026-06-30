import 'package:jaspr_ribbon_toolbar/model.dart';
import 'package:test/test.dart';

/// A faithful slice of the Windows File Explorer "View" tab from the reference
/// catalogue (`image ref/explorer_ribbon_toolbar.json`) — exercises every
/// control kind in one definition.
RibbonDefinition _explorerViewDefinition() {
  return RibbonDefinition(
    version: '2.0',
    projectType: 'web',
    tabs: [
      RibbonTab(
        caption: 'View',
        groups: [
          RibbonGroup(
            caption: 'Panes',
            items: [
              RibbonItem.splitButton(
                caption: 'Navigation pane',
                tag: 'view.nav',
                iconKey: 'nav-pane',
                menuItems: [
                  const RibbonMenuItem(
                    caption: 'Navigation pane',
                    tag: 'view.nav.toggle',
                  ),
                  const RibbonMenuItem(
                    caption: 'Expand to open folder',
                    tag: 'view.nav.expand',
                  ),
                ],
              ),
              RibbonItem.toggle(
                caption: 'Preview pane',
                tag: 'view.preview',
                isActive: false,
              ),
              RibbonItem.toggle(
                caption: 'Details pane',
                tag: 'view.details',
                isActive: false,
              ),
            ],
          ),
          RibbonGroup(
            caption: 'Show/hide',
            items: [
              RibbonItem.checkBox(
                caption: 'File name extensions',
                tag: 'view.ext',
                isChecked: false,
              ),
              RibbonItem.checkBox(
                caption: 'Hidden items',
                tag: 'view.hidden',
                isChecked: true,
              ),
              const RibbonItem.separator(),
              RibbonItem.small(
                caption: 'Hide selected items',
                tag: 'view.hide',
              ),
            ],
          ),
        ],
      ),
      RibbonTab.contextual(
        caption: 'Format',
        contextGroup: 'Picture Tools',
        accentColor: 0xFF2E7D32,
        groups: [
          RibbonGroup(
            caption: 'Picture Styles',
            items: [RibbonItem.large(caption: 'Crop', tag: 'pic.crop')],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('RibbonDefinition structure', () {
    final def = _explorerViewDefinition();

    test('separates standard and contextual tabs', () {
      expect(def.standardTabs, hasLength(1));
      expect(def.contextualTabs, hasLength(1));
      expect(def.contextualTabs.first.contextGroup, 'Picture Tools');
      expect(def.contextualTabsFor('Picture Tools'), hasLength(1));
      expect(def.contextualTabsFor('Table Tools'), isEmpty);
    });

    test('findItem walks the whole tree', () {
      expect(def.findItem('view.nav')?.jsonType, 'splitbutton');
      expect(def.findItem('view.hidden')?.isToggleActive, isTrue);
      expect(def.findItem('pic.crop')?.itemType, RibbonItemType.large);
      expect(def.findItem('missing'), isNull);
      expect(def.containsTag('view.ext'), isTrue);
      expect(def.containsTag('nope'), isFalse);
    });

    test('isToggleActive reports current state', () {
      expect(def.isToggleActive('view.hidden'), isTrue);
      expect(def.isToggleActive('view.ext'), isFalse);
      expect(def.isToggleActive('pic.crop'), isFalse);
    });
  });

  group('toggled() updates state immutably', () {
    test('flips a checkbox and leaves the rest intact', () {
      final def = _explorerViewDefinition();
      final next = def.toggled('view.ext');
      expect(
        identical(next, def),
        isFalse,
        reason: 'must return a new instance',
      );
      expect(
        next.isToggleActive('view.ext'),
        isTrue,
        reason: 'should have toggled on',
      );
      expect(
        next.isToggleActive('view.hidden'),
        isTrue,
        reason: 'untouched item must keep its state',
      );
      // original is unchanged (immutable)
      expect(def.isToggleActive('view.ext'), isFalse);
    });

    test('is a no-op for an unknown tag', () {
      final def = _explorerViewDefinition();
      expect(identical(def.toggled('unknown'), def), isTrue);
    });

    test('is a no-op for a non-toggling item', () {
      final def = _explorerViewDefinition();
      expect(identical(def.toggled('pic.crop'), def), isTrue);
    });
  });

  group('JSON round-trip', () {
    test('full definition survives toJsonString -> fromJsonString', () {
      final def = _explorerViewDefinition();
      final json = def.toJsonString();
      final restored = RibbonDefinition.fromJsonString(json);
      expect(restored, def);
    });

    test('emits the canonical .ribbon shape', () {
      final def = _explorerViewDefinition();
      final json = def.toJson();
      expect(json['version'], '2.0');
      expect(json['projectType'], 'web');
      final tabs = json['tabs'] as List<dynamic>;
      expect(tabs, hasLength(2));
      expect(
        (tabs[1] as Map<String, dynamic>)['contextGroup'],
        'Picture Tools',
      );
      final showHide = (tabs[0] as Map)['groups'][1] as Map<String, dynamic>;
      final types = (showHide['items'] as List)
          .cast<Map<String, dynamic>>()
          .map((i) => i['itemType']);
      expect(types, containsAll(['checkbox', 'separator', 'small']));
    });

    test('separators emit only their itemType', () {
      const item = RibbonItem.separator();
      expect(item.toJson(), {'itemType': 'separator'});
    });
  });
}
