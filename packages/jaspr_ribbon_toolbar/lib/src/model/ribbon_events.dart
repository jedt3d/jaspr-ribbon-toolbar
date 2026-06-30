/// Events emitted by the ribbon.
///
/// Counterparts of the Xojo events `ItemPressed`, `DropdownMenuAction` and
/// `CollapseStateChanged`. Modeled as a sealed type so a listener can exhaust
/// `switch` over every case.
sealed class RibbonEvent {
  const RibbonEvent();
}

/// A plain / toggle / checkbox / split-button body was activated.
///
/// Xojo: `Event ItemPressed(tag As String)`.
final class ItemPressedEvent extends RibbonEvent {
  const ItemPressedEvent(this.tag);
  final String tag;
  @override
  String toString() => 'ItemPressedEvent($tag)';
}

/// A menu entry inside a dropdown or split-button was chosen.
///
/// Xojo: `Event DropdownMenuAction(itemTag As String, menuItemTag As String)`.
final class DropdownMenuActionEvent extends RibbonEvent {
  const DropdownMenuActionEvent({
    required this.itemTag,
    required this.menuItemTag,
  });
  final String itemTag;
  final String menuItemTag;
  @override
  String toString() => 'DropdownMenuActionEvent($itemTag → $menuItemTag)';
}

/// The ribbon was collapsed or expanded via chevron / double-click.
///
/// Xojo: `Event CollapseStateChanged(isCollapsed As Boolean)`.
final class CollapseStateChangedEvent extends RibbonEvent {
  const CollapseStateChangedEvent(this.isCollapsed);
  final bool isCollapsed;
  @override
  String toString() => 'CollapseStateChangedEvent(collapsed=$isCollapsed)';
}

/// The active tab changed.
final class TabChangedEvent extends RibbonEvent {
  const TabChangedEvent(this.tabIndex, {this.contextGroup});
  final int tabIndex;
  final String? contextGroup;
  @override
  String toString() => 'TabChangedEvent($tabIndex)';
}
