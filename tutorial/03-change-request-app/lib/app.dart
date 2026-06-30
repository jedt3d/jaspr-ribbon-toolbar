import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_ribbon_toolbar/jaspr_ribbon_toolbar.dart';

/// Tutorial 3 page. The ribbon now has an **Insert** tab with a **Table**
/// button; **Copy** was renamed to **Copy file** (tag `clipboard.copy.file`);
/// the **Hidden items** checkbox drives the file list below; and the ribbon
/// follows the page colour scheme.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return const div([
      h1([Component.text('Tutorial 3 — Change request (CR-1042)')]),
      p(classes: 'lead', [
        Component.text(
          'Insert → Table opens a dialog; Copy file fires its renamed tag; '
          'Hidden items toggles the greyed entries below; the ribbon follows the page scheme.',
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
      h2([Component.text('File list')]),
      div(id: 'filelist', classes: 'filelist', []),
      h2([Component.text('Event log')]),
      ul(id: 'log', classes: 'log', []),
    ]);
  }
}
