import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

/// Tutorial 1 page: heading + the `<canvas>` ribbon (rendered by [RibbonToolbar])
/// + an event log. The controller that paints the canvas and emits events is
/// attached imperatively from `main.client.dart`.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return const div([
      h1([Component.text('Tutorial 1 — Embed the ribbon')]),
      p(classes: 'lead', [
        Component.text(
          'A canvas ribbon loaded at runtime from a .ribbon bundle. '
          'Click around — every interaction is logged below.',
        ),
      ]),
      div(classes: 'toolbar', [
        RibbonToolbar(
          definition: RibbonDefinition(tabs: []),
          id: 'ribbon',
          width: 1000,
          height: 118,
        ),
      ]),
      h2([Component.text('Event log')]),
      ul(id: 'log', classes: 'log', []),
    ]);
  }
}
