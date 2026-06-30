import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

/// Tutorial 2 page: the ribbon + a controls bar (dark mode / contextual tab)
/// + a live "Ribbon state" panel + an event log. The controller is attached
/// from `main.client.dart`, where events are mapped to behaviour.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return const div([
      h1([Component.text('Tutorial 2 — Events, toggles & contextual tabs')]),
      p(classes: 'lead', [
        Component.text('Buttons fire ItemPressed; split ▾ menus fire DropdownMenuAction; '
            'toggles & checkboxes keep state; the Format tab is contextual. Use the buttons below.'),
      ]),
      div(classes: 'toolbar', [
        RibbonToolbar(
          definition: RibbonDefinition(tabs: []),
          id: 'ribbon',
          width: 1000,
          height: 118,
        ),
      ]),
      div(id: 'controls', classes: 'controls', []),
      h2([Component.text('Ribbon state')]),
      div(id: 'state', classes: 'state', []),
      h2([Component.text('Event log')]),
      ul(id: 'log', classes: 'log', []),
    ]);
  }
}
