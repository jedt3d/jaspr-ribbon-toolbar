import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'version.dart';

/// The designer shell — three vertical rows: a full-width live preview, a
/// toolbar, and a 3-pane (structure · inspector · icons) work area. All
/// interactivity is wired imperatively from `main.client.dart` (see `Designer`).
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'app-root', [
      // Row 1 — full-width live preview
      div(classes: 'preview-row', [
        div(id: 'preview-host', classes: 'preview-host', []),
      ]),
      // Row 2 — toolbar
      div(classes: 'toolbar-row', [
        Component.text('Add:'),
        select(id: 'add-type', [
          option(attributes: {'value': 'tab'}, [Component.text('Tab')]),
          option(attributes: {'value': 'group'}, [Component.text('Group')]),
          option(
            attributes: {'value': 'large'},
            [Component.text('Large button')],
          ),
          option(
            attributes: {'value': 'small'},
            [Component.text('Small button')],
          ),
          option(
            attributes: {'value': 'dropdown'},
            [Component.text('Dropdown')],
          ),
          option(
            attributes: {'value': 'splitbutton'},
            [Component.text('Split button')],
          ),
          option(attributes: {'value': 'toggle'}, [Component.text('Toggle')]),
          option(
            attributes: {'value': 'checkbox'},
            [Component.text('Checkbox')],
          ),
          option(
            attributes: {'value': 'separator'},
            [Component.text('Separator')],
          ),
        ]),
        button(id: 'btn-add', classes: 'btn primary', [Component.text('Add')]),
        button(id: 'btn-delete', classes: 'btn danger', [
          Component.text('Delete'),
        ]),
        div(classes: 'spacer', []),
        button(id: 'btn-new', classes: 'btn', [Component.text('New')]),
        button(id: 'btn-load', classes: 'btn', [Component.text('Load')]),
        button(id: 'btn-save', classes: 'btn', [
          Component.text('Save .ribbon'),
        ]),
      ]),
      // Row 3 — three panes
      div(classes: 'main', [
        div(classes: 'panel', [
          h3([Component.text('Structure')]),
          div(id: 'tree', classes: 'body', []),
        ]),
        div(classes: 'panel', [
          h3([Component.text('Inspector')]),
          div(id: 'inspector', classes: 'body', []),
        ]),
        div(classes: 'panel', [
          h3([Component.text('Icons')]),
          div(classes: 'icon-toolbar', [
            button(id: 'btn-upload-icon', classes: 'btn primary', [
              Component.text('Upload SVG/PNG'),
            ]),
          ]),
          div(id: 'icon-library', classes: 'body iconlib', []),
        ]),
      ]),
      // Status bar
      div(classes: 'statusbar', [
        span(id: 'status', [Component.text('Ready.')]),
        span([Component.text('jaspr-ribbon-toolbar designer · v$appVersion')]),
      ]),
    ]);
  }
}
