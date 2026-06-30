/// Tutorial 3 — entrypoint.
///
/// The behaviour changes from CR-1042:
///  - `insert.table` (new Insert tab) opens a "dialog".
///  - `clipboard.copy.file` (renamed from `clipboard.copy`) is the Copy action.
///  - `view.hidden` (a checkbox) drives `showHiddenFiles` and refreshes the list.
///  - the ribbon palette follows `prefers-color-scheme`.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:jaspr_ribbon_toolbar/web.dart';
import 'package:web/web.dart' as web;

import 'app.dart';

RibbonCanvasController? _ribbon;

// App state.
bool _showHidden = true; // mirrors the bundle's "Hidden items: checked".

// Command map — note the renamed `clipboard.copy.file` and the new `insert.table`.
final _commands = <String, void Function()>{
  'clipboard.paste': () => log('Paste'),
  'clipboard.cut': () => log('Cut'),
  'clipboard.copy.file': () => log('Copy file'), // CR #4: renamed tag
  'organize.rename': () => log('Rename'),
  'organize.delete.recycle': () => log('Delete → Recycle'),
  'organize.delete.permanent': () => log('Delete → Permanently'),
  'insert.table': insertTable, // CR #1: new
};

void main() {
  runApp(const App());
  Future<void>.microtask(() async {
    await attachRibbon();
    syncDarkMode(); // CR #3: follow the page scheme
    refreshFileList();
  });
}

Future<void> attachRibbon() async {
  final res = await web.window.fetch('assets/ribbon.bundle.json'.toJS).toDart;
  final text = (await res.text().toDart).toDart;
  final definition = RibbonDefinition.fromJsonString(text);
  final icons = <String, IconSource>{};
  for (final entry in definition.icons.entries) {
    icons[entry.key] = entry.value.kind == IconAssetKind.svg
        ? IconSource.svg(entry.value.data)
        : IconSource.png(entry.value.data);
  }
  final el = web.document.getElementById('ribbon');
  if (el == null) return;
  _ribbon = RibbonCanvasController(
    canvas: el as web.HTMLCanvasElement,
    definition: definition,
    colors: RibbonColors.light,
    icons: IconRegistry.assets(icons),
    onEvent: handleEvent,
  )..attach();
}

void handleEvent(RibbonEvent e) {
  switch (e) {
    case ItemPressedEvent(:final tag):
      if (tag == 'view.hidden') {
        // CR #2: the checkbox drives a real app setting + list refresh.
        _showHidden = _ribbon?.getToggleState('view.hidden') ?? false;
        refreshFileList();
        log('Hidden items → ${_showHidden ? 'on' : 'off'}');
      } else {
        _commands[tag]?.call();
        log('ItemPressed · $tag');
      }
    case DropdownMenuActionEvent(:final menuItemTag):
      _commands[menuItemTag]?.call();
      log('DropdownMenuAction · $menuItemTag');
    case CollapseStateChangedEvent(:final isCollapsed):
      log('CollapseStateChanged · $isCollapsed');
    case TabChangedEvent(:final tabIndex):
      log('TabChanged · $tabIndex');
  }
}

// CR #1 — the new Insert → Table action.
void insertTable() {
  // In a real app: open a table-size picker. Here we surface a dialog via the
  // browser and log the outcome.
  web.window.alert('Insert table — pick dimensions (demo)');
  log('Insert → Table');
}

// CR #3 — the ribbon palette follows the page colour scheme, live.
void syncDarkMode() {
  final mql = web.window.matchMedia('(prefers-color-scheme: dark)');
  void apply() {
    final dark = mql.matches;
    _ribbon?.setDarkMode(dark);
    final body = web.document.body;
    if (body != null) {
      if (dark) {
        body.classList.add('dark');
      } else {
        body.classList.remove('dark');
      }
    }
  }

  apply();
  mql.addEventListener('change', ((web.Event _) => apply()).toJS);
}

// The file list reacts to the Hidden items checkbox (CR #2).
void refreshFileList() {
  final el = web.document.getElementById('filelist');
  if (el == null) return;
  const files = [
    ('report.pdf', false),
    ('notes.txt', false),
    ('.secrets', true),
    ('budget.xlsx', true),
  ];
  el.textContent = '';
  for (final (name, hidden) in files) {
    if (hidden && !_showHidden) continue;
    final row = web.HTMLDivElement()..textContent = name;
    if (hidden) row.className = 'hidden';
    el.append(row);
  }
  if (el.childNodes.length == 0) {
    el.textContent = '(no visible files)';
  }
}

void log(String text) {
  final log = web.document.getElementById('log');
  if (log == null) return;
  final li = web.HTMLLIElement()..textContent = text;
  log.prepend(li);
}
