import 'package:jaspr_ribbon_toolbar/model.dart';

/// Pure (DOM-free, web-free) designer logic — extracted so it can be unit-tested
/// on the VM. The imperative `Designer` delegates to these.

/// Allows only lowercase letters and dots (`[a-z.]`); other characters dropped.
String sanitizeKey(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z.]'), '');

/// Returns [base], or `base.1`, `base.2`, … until it does not collide with a key
/// in [existing].
String uniqueIconKey(String base, Iterable<String> existing) {
  final taken = existing.toSet();
  if (!taken.contains(base)) return base;
  var i = 1;
  while (taken.contains('$base.$i')) {
    i++;
  }
  return '$base.$i';
}

/// Derives a valid icon key from a filename: drops the extension, lowercases,
/// turns separators into dots, strips anything else. Falls back to `icon`.
String deriveIconKey(String filename) {
  final dot = filename.lastIndexOf('.');
  final base = dot > 0 ? filename.substring(0, dot) : filename;
  var key = base.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '.');
  key = key.replaceAll(RegExp(r'[^a-z.]'), '');
  key = key.replaceAll(RegExp(r'\.{2,}'), '.');
  key = key.replaceAll(RegExp(r'^\.+|\.+$'), '');
  return key.isEmpty ? 'icon' : key;
}

/// Rebuilds an item as a different control kind, preserving caption/tag/icon/
/// tooltip/enabled (+ menu items where relevant, + toggle state where relevant).
RibbonItem rebuildItemAs(RibbonItem it, String type) {
  final cap = it.caption;
  final tag = it.tag;
  final tip = it.tooltipText;
  final icon = it.iconKey;
  final menu = it.menuItems;
  switch (type) {
    case 'small':
      return RibbonItem.small(
        caption: cap,
        tag: tag,
        tooltipText: tip,
        iconKey: icon,
        isEnabled: it.isEnabled,
      );
    case 'dropdown':
      return RibbonItem.dropdown(
        caption: cap,
        tag: tag,
        tooltipText: tip,
        iconKey: icon,
        isEnabled: it.isEnabled,
        menuItems: menu,
      );
    case 'splitbutton':
      return RibbonItem.splitButton(
        caption: cap,
        tag: tag,
        tooltipText: tip,
        iconKey: icon,
        isEnabled: it.isEnabled,
        menuItems: menu,
      );
    case 'toggle':
      return RibbonItem.toggle(
        caption: cap,
        tag: tag,
        isActive: it.isToggleActive,
        tooltipText: tip,
        iconKey: icon,
        isEnabled: it.isEnabled,
      );
    case 'checkbox':
      return RibbonItem.checkBox(
        caption: cap,
        tag: tag,
        isChecked: it.isToggleActive,
        tooltipText: tip,
        isEnabled: it.isEnabled,
      );
    case 'separator':
      return const RibbonItem.separator();
    case 'large':
    default:
      return RibbonItem.large(
        caption: cap,
        tag: tag,
        tooltipText: tip,
        iconKey: icon,
        isEnabled: it.isEnabled,
        menuItems: menu,
      );
  }
}

/// Rebuilds a tab preserving its groups, toggling/setting contextual fields.
/// (`RibbonTab` is immutable with two constructors, so contextual changes
/// require reconstruction.)
RibbonTab rebuildTab(
  RibbonTab t, {
  String? caption,
  bool? isContextual,
  String? contextGroup,
  int? accentColor,
}) {
  final cap = caption ?? t.caption;
  final ctx = isContextual ?? t.isContextual;
  if (!ctx) return RibbonTab(caption: cap, groups: t.groups, keyTip: t.keyTip);
  var grp = contextGroup ?? t.contextGroup ?? '';
  if (grp.isEmpty) grp = 'New context';
  return RibbonTab.contextual(
    caption: cap,
    groups: t.groups,
    contextGroup: grp,
    accentColor: accentColor ?? t.accentColor,
    keyTip: t.keyTip,
  );
}

/// Returns a copy of [model] with every `iconKey == oldKey` updated to [newKey].
RibbonDefinition retargetIcon(
  RibbonDefinition model,
  String oldKey,
  String newKey,
) {
  return model.copyWith(
    tabs: model.tabs
        .map(
          (t) => t.copyWith(
            groups: t.groups
                .map(
                  (g) => g.copyWith(
                    items: g.items
                        .map(
                          (it) => it.iconKey == oldKey
                              ? it.copyWith(iconKey: newKey)
                              : it,
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );
}
