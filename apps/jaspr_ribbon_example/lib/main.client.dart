/// The entrypoint for the **client** demo.
///
/// Renders the page, then attaches a [RibbonCanvasController] to the `<canvas>`
/// produced by [RibbonToolbar]. All painting and pointer-event → [RibbonEvent]
/// translation happens client-side via the Canvas 2D API. Two demo controls
/// (dark mode + contextual "Picture Tools" tab) are wired to the controller.
library;

import 'dart:async';

import 'package:jaspr/client.dart';
import 'package:jaspr_ribbon_toolbar/web.dart';
import 'package:web/web.dart' as web;

import 'app.dart';
import 'explorer_ribbon.dart';

RibbonCanvasController? _controller;

void main() {
  runApp(const App());
  Future<void>.microtask(() {
    attachRibbon();
    buildControls();
  });
}

void attachRibbon() {
  final el = web.document.getElementById('ribbon');
  if (el == null) return;
  _controller = RibbonCanvasController(
    canvas: el as web.HTMLCanvasElement,
    definition: explorerRibbon,
    colors: RibbonColors.light,
    icons: IconRegistry.assets(const {
      'paste': IconSource.svg('icons/paste.svg'),
      'cut': IconSource.svg('icons/cut.svg'),
      'copy': IconSource.svg('icons/copy.svg'),
      'copy-path': IconSource.svg('icons/copy-path.svg'),
      'delete': IconSource.svg('icons/delete.svg'),
      'rename': IconSource.svg('icons/rename.svg'),
      'nav-pane': IconSource.svg('icons/nav-pane.svg'),
      'preview-pane': IconSource.svg('icons/preview-pane.svg'),
      'details-pane': IconSource.svg('icons/details-pane.svg'),
      'hide': IconSource.svg('icons/hide.svg'),
      'crop': IconSource.svg('icons/crop.svg'),
    }),
    onEvent: logEvent,
  )..attach();
}

/// Builds the demo control bar (dark-mode + contextual tab toggles) and wires
/// it to the controller.
void buildControls() {
  final bar = web.HTMLDivElement();
  bar.setAttribute(
    'style',
    'margin:6px 0 16px;display:flex;gap:8px;align-items:center;',
  );

  var dark = false;
  final darkBtn = makeButton('🌙 Dark mode');
  darkBtn.onClick.listen((_) {
    dark = !dark;
    _controller?.setDarkMode(dark);
    darkBtn.textContent = dark ? '☀️ Light mode' : '🌙 Dark mode';
    final body = web.document.body;
    if (body != null) {
      body.style.background = dark ? '#282828' : '#ffffff';
      body.style.color = dark ? '#dcdcdc' : '#1e1e1e';
    }
  });

  final ctxBtn = makeButton('🖼 Show "Picture Tools" tab');
  ctxBtn.onClick.listen((_) {
    final visible = _controller?.toggleContextGroup('Picture Tools') ?? false;
    ctxBtn.textContent = visible
        ? '🖼 Hide "Picture Tools" tab'
        : '🖼 Show "Picture Tools" tab';
    if (visible) logSimple('ContextualTab · showed Picture Tools');
  });

  bar.append(darkBtn);
  bar.append(ctxBtn);
  // Insert the control bar right before the toolbar canvas.
  final toolbar = web.document.querySelector('.toolbar');
  toolbar?.before(bar);
}

web.HTMLButtonElement makeButton(String label) {
  final b = web.HTMLButtonElement();
  b.textContent = label;
  b.setAttribute(
    'style',
    'font:12px "Segoe UI",system-ui,sans-serif;padding:6px 12px;border:1px solid #d2d2d2;'
        'border-radius:6px;background:#fff;color:#1e1e1e;cursor:pointer;',
  );
  return b;
}

void logSimple(String text) {
  final log = web.document.getElementById('log');
  if (log == null) return;
  final li = web.HTMLLIElement()..textContent = text;
  log.prepend(li);
}

/// Appends a one-line summary of each ribbon event to the on-page `<ul id="log">`.
void logEvent(RibbonEvent event) {
  final log = web.document.getElementById('log');
  if (log == null) return;
  final li = web.HTMLLIElement();
  String text;
  switch (event) {
    case ItemPressedEvent(:final tag):
      text = 'ItemPressed · $tag';
    case DropdownMenuActionEvent(:final itemTag, :final menuItemTag):
      text = 'DropdownMenuAction · $itemTag ▾ $menuItemTag';
    case CollapseStateChangedEvent(:final isCollapsed):
      text = 'CollapseStateChanged · collapsed=$isCollapsed';
    case TabChangedEvent(:final tabIndex):
      text = 'TabChanged · index=$tabIndex';
  }
  li.textContent = text;
  log.prepend(li);
}
