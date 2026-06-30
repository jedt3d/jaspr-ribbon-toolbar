/// Tutorial 1 — entrypoint.
///
/// Loads `assets/ribbon.bundle.json`, builds an [IconRegistry] from the
/// bundle's embedded icons, and attaches a [RibbonCanvasController] to the
/// `<canvas>` rendered by [App]. Events are appended to the on-page log.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:jaspr/client.dart';
import 'package:jaspr_ribbon_toolbar/web.dart';
import 'package:web/web.dart' as web;

import 'app.dart';

void main() {
  runApp(const App());
  Future<void>.microtask(attachRibbon);
}

Future<void> attachRibbon() async {
  // 1) Load the .ribbon bundle.
  final res = await web.window.fetch('assets/ribbon.bundle.json'.toJS).toDart;
  final text = (await res.text().toDart).toDart;
  final definition = RibbonDefinition.fromJsonString(text);

  // 2) Build an IconRegistry from the bundle's embedded icons.
  final icons = <String, IconSource>{};
  for (final entry in definition.icons.entries) {
    icons[entry.key] = entry.value.kind == IconAssetKind.svg
        ? IconSource.svg(entry.value.data)
        : IconSource.png(entry.value.data);
  }

  // 3) Attach the controller to the canvas rendered by App.
  final el = web.document.getElementById('ribbon');
  if (el == null) return;
  RibbonCanvasController(
    canvas: el as web.HTMLCanvasElement,
    definition: definition,
    colors: RibbonColors.light,
    icons: IconRegistry.assets(icons),
    onEvent: logEvent,
  ).attach();
}

void logEvent(RibbonEvent e) {
  final log = web.document.getElementById('log');
  if (log == null) return;
  final li = web.HTMLLIElement();
  String text;
  switch (e) {
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
