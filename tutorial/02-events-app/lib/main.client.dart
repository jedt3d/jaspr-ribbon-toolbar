/// Tutorial 2 — entrypoint.
///
/// Builds on Tutorial 1: the same bundle-load + controller-attach, but now the
/// `onEvent` callback routes real behaviour — a command map for buttons and
/// dropdown menu items, toggle/checkbox state is read and reflected into a
/// "Ribbon state" panel, a contextual tab is revealed on demand, and dark mode
/// can be toggled.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:jaspr_ribbon_toolbar/web.dart';
import 'package:web/web.dart' as web;

import 'app.dart';

RibbonCanvasController? _ribbon;

// A tiny command map: tag → action. Plain buttons and split-button bodies fire
// ItemPressed(tag); dropdown menu choices fire DropdownMenuAction(menuItemTag).
final _commands = <String, void Function()>{
  'clipboard.paste': () => flash('Paste'),
  'clipboard.cut': () => flash('Cut'),
  'clipboard.copy': () => flash('Copy'),
  'organize.rename': () => flash('Rename'),
  'organize.delete.recycle': () => flash('Delete → Recycle'),
  'organize.delete.permanent': () => flash('Delete → Permanently'),
  'view.hide': () => flash('Hide selected'),
};

void main() {
  runApp(const App());
  Future<void>.microtask(() async {
    await attachRibbon();
    buildControls();
    renderState();
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
      switch (tag) {
        // Toggles & checkboxes: the controller already flipped the state;
        // read the fresh value and apply it.
        case 'view.preview':
        case 'view.details':
        case 'view.hidden':
          applyToggle(tag);
        default:
          _commands[tag]?.call();
      }
      logEvent('ItemPressed · $tag');
    case DropdownMenuActionEvent(:final itemTag, :final menuItemTag):
      _commands[menuItemTag]?.call();
      logEvent('DropdownMenuAction · $itemTag ▾ $menuItemTag');
    case CollapseStateChangedEvent(:final isCollapsed):
      logEvent('CollapseStateChanged · collapsed=$isCollapsed');
    case TabChangedEvent(:final tabIndex):
      logEvent('TabChanged · index=$tabIndex');
  }
  renderState();
}

void applyToggle(String tag) {
  final on = _ribbon?.getToggleState(tag) ?? false;
  // Here you'd drive your real UI; we just reflect it in the state panel.
  flash('$tag → ${on ? 'on' : 'off'}');
}

// ── Controls bar (dark mode + contextual tab) ───────────────────────────────

void buildControls() {
  final bar = web.document.getElementById('controls');
  if (bar == null) return;

  var dark = false;
  final darkBtn = button('🌙 Dark mode');
  darkBtn.onClick.listen((_) {
    dark = !dark;
    _ribbon?.setDarkMode(dark);
    darkBtn.textContent = dark ? '☀️ Light mode' : '🌙 Dark mode';
  });

  final ctxBtn = button('🖼 Show "Picture Tools" tab');
  ctxBtn.onClick.listen((_) {
    final visible = _ribbon?.toggleContextGroup('Picture Tools') ?? false;
    ctxBtn.textContent = visible
        ? '🖼 Hide "Picture Tools" tab'
        : '🖼 Show "Picture Tools" tab';
  });

  bar.append(darkBtn);
  bar.append(ctxBtn);
}

// ── State panel + event log ─────────────────────────────────────────────────

void renderState() {
  final el = web.document.getElementById('state');
  if (el == null) return;
  el.textContent = '';
  void row(String k, bool on) {
    final d = web.HTMLDivElement();
    final kap = web.HTMLSpanElement()
      ..className = 'k'
      ..textContent = '$k: ';
    final val = web.HTMLSpanElement()..textContent = on ? 'on' : 'off';
    if (on) val.className = 'on';
    d.append(kap);
    d.append(val);
    el.append(d);
  }

  row('Preview pane', _ribbon?.getToggleState('view.preview') ?? false);
  row('Details pane', _ribbon?.getToggleState('view.details') ?? false);
  row('Hidden items', _ribbon?.getToggleState('view.hidden') ?? false);
}

void flash(String msg) {
  logEvent('→ $msg');
}

void logEvent(String text) {
  final log = web.document.getElementById('log');
  if (log == null) return;
  final li = web.HTMLLIElement()..textContent = text;
  log.prepend(li);
}

web.HTMLButtonElement button(String label) {
  final b = web.HTMLButtonElement()
    ..textContent = label
    ..className = 'primary';
  return b;
}
