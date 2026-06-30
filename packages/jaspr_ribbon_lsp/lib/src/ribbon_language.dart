import 'package:jaspr_ribbon_toolbar/model.dart';

/// The seven `itemType` tokens, in catalogue order.
const itemTypes = [
  'large',
  'small',
  'dropdown',
  'splitbutton',
  'toggle',
  'checkbox',
  'separator',
];

/// Short documentation for each `itemType` token (used by completion detail +
/// hover).
const itemTypeDocs = <String, String>{
  'large':
      'Large button — 32px icon + caption below; spans the full group height. (Xojo kItemTypeLarge = 0)',
  'small':
      'Small button — 16px icon + caption to the right; stacks three-per-column. (kItemTypeSmall = 1)',
  'dropdown':
      'Dropdown button — any click opens the popup menu. (kItemTypeDropdown = 2)',
  'splitbutton':
      'Split button — body click fires ItemPressed, arrow click opens the menu. (ItemType 2 + IsSplitButton)',
  'toggle':
      'Toggle button — press-hold on/off state (e.g. Preview pane). No glyph.',
  'checkbox':
      'Check box — ☐/☑ glyph + caption row; toggles isToggleActive. (kItemTypeCheckBox = 3)',
  'separator':
      'Separator — a non-interactive column boundary inside a group. (kItemTypeSeparator = 4)',
};

/// Which value field is being edited at [character] on [line].
enum FieldContext { itemType, iconKey, other }

/// Inspects the text before the cursor on a line to decide what to complete.
FieldContext detectFieldContext(String line, int character) {
  final clamped = character < 0
      ? 0
      : (character > line.length ? line.length : character);
  final before = line.substring(0, clamped);
  if (RegExp(r'"itemType"\s*:\s*"?').hasMatch(before))
    return FieldContext.itemType;
  if (RegExp(r'"iconKey"\s*:\s*"?').hasMatch(before))
    return FieldContext.iconKey;
  return FieldContext.other;
}

/// All `itemType` suggestions.
List<String> suggestItemTypes() => List<String>.unmodifiable(itemTypes);

/// Every icon key referenced by the document — item `iconKey`s plus the keys of
/// an embedded `icons` asset map. Returns an empty list if the document does not
/// parse.
List<String> suggestIconKeys(String source) {
  try {
    final def = RibbonDefinition.fromJsonString(source);
    final keys = <String>{
      ...def.icons.keys,
      for (final tab in def.tabs)
        for (final group in tab.groups)
          for (final item in group.items)
            if (item.iconKey != null) item.iconKey!,
    };
    return keys.toList()..sort();
  } catch (_) {
    return const [];
  }
}

/// Documentation for an `itemType` [token], or `null` if unknown.
String? itemTypeDoc(String token) => itemTypeDocs[token];

/// Extracts the whitespace/quote-delimited word at [character] on [line].
String wordAt(String line, int character) {
  if (line.isEmpty) return '';
  final clamped = character < 0
      ? 0
      : (character > line.length ? line.length : character);
  var start = clamped;
  while (start > 0 && _isWordChar(line.codeUnitAt(start - 1))) {
    start--;
  }
  var end = clamped;
  while (end < line.length && _isWordChar(line.codeUnitAt(end))) {
    end++;
  }
  return line.substring(start, end);
}

bool _isWordChar(int code) =>
    (code >= 0x30 && code <= 0x39) || // 0-9
    (code >= 0x41 && code <= 0x5A) || // A-Z
    (code >= 0x61 && code <= 0x7A) || // a-z
    code == 0x2E; // .
