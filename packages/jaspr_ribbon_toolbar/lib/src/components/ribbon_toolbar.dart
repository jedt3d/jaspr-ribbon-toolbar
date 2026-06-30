import 'package:jaspr/jaspr.dart';

import '../model/ribbon_definition.dart';
import '../model/ribbon_events.dart';
import 'icon_registry.dart';

export '../model/ribbon_definition.dart';
export '../model/ribbon_events.dart';
export 'icon_registry.dart';

/// A Microsoft Office–style ribbon toolbar rendered to an HTML5 `<canvas>`.
///
/// This is the Jaspr counterpart of Xojo's `XjRibbon` canvas control. The
/// component renders a single `<canvas>` element and forwards interaction
/// events via the [onEvent] callback (mirroring Xojo's `ItemPressed`,
/// `DropdownMenuAction` and `CollapseStateChanged` events).
///
/// The low-level paint loop (the Xojo `Paint` logic ported to the Canvas 2D
/// context) is wired through an `RibbonPainter` in milestone 2; until then the
/// component renders the correctly-sized canvas and exposes the full data
/// contract so designers, tests, and the LSP server can be built against it.
///
/// ```dart
/// RibbonToolbar(
///   definition: myRibbon,
///   darkMode: false,
///   collapsed: false,
///   icons: IconRegistry.assets({'paste': 'icons/paste.svg'}),
///   onEvent: (event) => print(event),
/// )
/// ```
class RibbonToolbar extends StatelessComponent {
  const RibbonToolbar({
    required this.definition,
    this.darkMode = false,
    this.collapsed = false,
    this.activeTabIndex = 0,
    this.width = 800,
    this.height = 118,
    this.icons = const IconRegistry.empty(),
    this.onEvent,
    this.id,
    super.key,
  });

  /// The full ribbon structure to render.
  final RibbonDefinition definition;

  /// Whether to use the dark colour palette.
  final bool darkMode;

  /// Whether the ribbon band is collapsed (tabs-only).
  final bool collapsed;

  /// Index of the currently selected tab.
  final int activeTabIndex;

  /// Logical canvas width in CSS pixels.
  final int width;

  /// Logical canvas height in CSS pixels (expanded band).
  final int height;

  /// Icon asset registry, resolving [RibbonItem.iconKey]s to SVG/PNG sources.
  final IconRegistry icons;

  /// Listener for `ItemPressed`, `DropdownMenuAction`, `CollapseStateChanged`
  /// and `TabChanged` events.
  final void Function(RibbonEvent event)? onEvent;

  /// Optional id for the underlying `<canvas>` element.
  final String? id;

  @override
  Component build(BuildContext context) {
    final visibleTabs = definition.tabs.length;
    final activeTab = definition.tabs.isEmpty
        ? null
        : definition.tabs[activeTabIndex.clamp(0, visibleTabs - 1)];

    return Component.element(
      tag: 'canvas',
      id: id,
      attributes: {
        'width': '${collapsed ? width : width}',
        'height': '${collapsed ? _kCollapsedHeight : height}',
        'role': 'toolbar',
        'aria-label': activeTab?.caption ?? 'Ribbon',
        'aria-disabled': 'false',
        'data-ribbon-version': definition.version,
        'data-dark-mode': darkMode.toString(),
        'data-collapsed': collapsed.toString(),
        'data-active-tab': activeTabIndex.toString(),
      },
      children: const [],
    );
  }

  /// Height of the collapsed (tab-strip only) band, matching Xojo.
  static const int _kCollapsedHeight = 28;
}
