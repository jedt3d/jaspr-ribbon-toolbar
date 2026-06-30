import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

import 'explorer_ribbon.dart';

/// The demo page. Renders the heading, the `<canvas>` ribbon (via the
/// [RibbonToolbar] component), and an event log. The canvas painting + pointer
/// handling is driven imperatively from `main.client.dart` via
/// [RibbonCanvasController].
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return div([
      const h1([Component.text('jaspr-ribbon-toolbar')]),
      const p(classes: 'lead', [
        Component.text(
          'A canvas-rendered MS Office-style ribbon for Jaspr — a 1:1 port of the Xojo XjRibbon. '
          'Hover, click tabs, toggle the collapse chevron, open the Delete ▾ / Navigation pane ▾ menus.',
        ),
      ]),
      div(classes: 'toolbar', [
        RibbonToolbar(
          definition: explorerRibbon,
          id: 'ribbon',
          width: 1000,
          height: 118,
        ),
      ]),
      const h2([Component.text('Event log')]),
      const ul(id: 'log', classes: 'log', []),
    ]);
  }
}
