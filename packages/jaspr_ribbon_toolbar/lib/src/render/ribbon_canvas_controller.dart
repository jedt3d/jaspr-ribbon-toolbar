import 'dart:async';

import 'package:web/web.dart' as web;

import '../components/icon_registry.dart';
import '../model/item_type.dart';
import '../model/ribbon_definition.dart';
import '../model/ribbon_events.dart';
import '../theme/ribbon_colors.dart';
import 'ribbon_geometry.dart';
import 'ribbon_layout.dart';
import 'ribbon_painter.dart';
import 'menu_overlay.dart';
import 'web_canvas_surface.dart';

/// Imperative driver that paints a [RibbonDefinition] into a `<canvas>` and
/// translates browser pointer events into [RibbonEvent]s — the Jaspr/web
/// counterpart of Xojo's `XjRibbon` canvas control.
///
/// The `RibbonToolbar` component renders the `<canvas>` element; a controller
/// (created in the host app or, later, inside the component lifecycle) owns the
/// paint + interaction loop. See `examples` / the designer for usage.
class RibbonCanvasController {
  RibbonCanvasController({
    required web.HTMLCanvasElement canvas,
    required RibbonDefinition definition,
    required RibbonColors colors,
    IconRegistry icons = const IconRegistry.empty(),
    this.darkMode = false,
    int initialTabIndex = 0,
    bool initiallyCollapsed = false,
    this.onEvent,
  }) : _canvas = canvas,
       _def = definition,
       _icons = icons {
    _painter = RibbonPainter(colors: colors);
    _state = RibbonPaintState(
      activeTabIndex: initialTabIndex,
      collapsed: initiallyCollapsed,
    );
  }

  final web.HTMLCanvasElement _canvas;
  RibbonDefinition _def;
  IconRegistry _icons;
  late RibbonPainter _painter;
  final bool darkMode;
  final void Function(RibbonEvent event)? onEvent;

  late final WebCanvasSurface _surface;
  RibbonLayout? _layout;
  RibbonPaintState _state = const RibbonPaintState();
  final List<StreamSubscription<dynamic>> _subs = [];
  final Set<String> _visibleContextGroups = {};
  MenuOverlay? _menu;
  bool _attached = false;

  // CSS-pixel dimensions, captured from the element's width/height attributes
  // before HiDPI scales the backing store.
  late double _cssWidth;
  late double _cssHeight;

  double get _effectiveHeight =>
      _state.collapsed ? RibbonGeometry.collapsedHeight : _cssHeight;

  /// Connects to the 2D context, preloads icons, paints, and binds events.
  void attach() {
    if (_attached) return;
    _attached = true;
    _cssWidth = _canvas.width.toDouble();
    _cssHeight = _canvas.height.toDouble();
    final ctx = _canvas.getContext('2d');
    if (ctx == null) return;
    _surface = WebCanvasSurface(ctx as web.CanvasRenderingContext2D);
    resetIconImages();
    _preloadIcons();
    _setupCanvas();
    repaint();
    _subs.add(_canvas.onMouseDown.listen(_onDown));
    _subs.add(_canvas.onMouseMove.listen(_onMove));
    _subs.add(_canvas.onMouseUp.listen(_onUp));
    _subs.add(_canvas.onMouseLeave.listen((_) => _onLeave()));
  }

  /// Tears down listeners (call when the element leaves the DOM).
  void detach() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _attached = false;
  }

  /// Recomputes layout and repaints. Cheap to call on every interaction.
  void repaint() {
    _layout = RibbonLayout.compute(
      definition: _def,
      surface: _surface,
      width: _cssWidth,
      height: _effectiveHeight,
      activeTabIndex: _state.activeTabIndex,
      collapsed: _state.collapsed,
      visibleContextGroups: _visibleContextGroups,
    );
    _surface.ctx.save();
    _surface.ctx.beginPath();
    _surface.ctx.rect(0, 0, _cssWidth, _effectiveHeight);
    _surface.ctx.clip();
    _surface.ctx.clearRect(0, 0, _cssWidth, _effectiveHeight);
    _painter.paint(_surface, _layout!, _state);
    _surface.ctx.restore();
  }

  /// Sizes the backing store for HiDPI (`devicePixelRatio`) and scales the
  /// context so all drawing uses CSS pixels. Also shrinks the element when
  /// collapsed so the host layout collapses too.
  void _setupCanvas() {
    final dpr = web.window.devicePixelRatio.clamp(1.0, 3.0).toDouble();
    final h = _effectiveHeight;
    // Setting canvas.width resets the context transform to identity, so the
    // subsequent scale() is idempotent across resize() calls.
    _canvas.width = (_cssWidth * dpr).round();
    _canvas.height = (h * dpr).round();
    _canvas.style.width = '${_cssWidth}px';
    _canvas.style.height = '${h}px';
    _surface.ctx.scale(dpr, dpr);
  }

  /// Resizes the canvas (CSS pixels) and re-paints — used by the designer when
  /// its preview panel resizes.
  void resize(double cssWidth, double cssHeight) {
    _cssWidth = cssWidth;
    _cssHeight = cssHeight;
    _setupCanvas();
    repaint();
  }

  /// Swaps the icon registry (e.g. after uploading assets in the designer),
  /// preloads the new icons, and repaints.
  void setIcons(IconRegistry icons) {
    _icons = icons;
    resetIconImages();
    _preloadIcons();
    repaint();
  }

  // ── Public API: tabs, collapse, dark mode, contextual groups ──────────────

  /// Switches to the tab at [index] (if it is currently visible).
  void setActiveTab(int index) {
    if (index < 0 || index >= _def.tabs.length) return;
    if (_layout!.tabs.every((t) => !identical(t.tab, _def.tabs[index]))) return;
    _state = _state.copyWith(activeTabIndex: index, hoveredTabIndex: -1);
    onEvent?.call(TabChangedEvent(index));
    repaint();
  }

  /// Replaces the colour palette and repaints. Use with [RibbonColors.dark]
  /// / [RibbonColors.light] to toggle dark mode at runtime.
  void setColors(RibbonColors colors) {
    _painter = RibbonPainter(colors: colors);
    repaint();
  }

  /// Convenience: toggles between [RibbonColors.light] and [RibbonColors.dark].
  void setDarkMode(bool enabled) =>
      setColors(RibbonColors.resolve(isDarkMode: enabled));

  /// Shows all contextual tabs belonging to [contextGroup].
  void showContextGroup(String contextGroup) {
    if (_visibleContextGroups.add(contextGroup)) repaint();
  }

  /// Hides all contextual tabs belonging to [contextGroup]. If the active tab
  /// was in that group, the first standard tab becomes active.
  void hideContextGroup(String contextGroup) {
    if (!_visibleContextGroups.remove(contextGroup)) return;
    final active =
        _state.activeTabIndex >= 0 && _state.activeTabIndex < _def.tabs.length
        ? _def.tabs[_state.activeTabIndex]
        : null;
    if (active != null &&
        active.isContextual &&
        active.contextGroup == contextGroup) {
      _state = _state.copyWith(
        activeTabIndex: _def.tabs.indexWhere((t) => !t.isContextual),
      );
    }
    repaint();
  }

  /// Toggles [contextGroup] on/off and returns the new visibility.
  bool toggleContextGroup(String contextGroup) {
    if (_visibleContextGroups.contains(contextGroup)) {
      hideContextGroup(contextGroup);
      return false;
    }
    showContextGroup(contextGroup);
    return true;
  }

  /// Current toggle/checkbox state of the item with [tag].
  bool getToggleState(String tag) => _def.isToggleActive(tag);

  /// Sets the toggle/checkbox state of [tag] and repaints.
  void setToggleState(String tag, bool value) {
    final current = _def.isToggleActive(tag);
    if (current != value) _def = _def.toggled(tag);
    repaint();
  }

  void _preloadIcons() {
    for (final tab in _def.tabs) {
      for (final group in tab.groups) {
        for (final item in group.items) {
          final key = item.iconKey;
          if (key != null) {
            final src = _iconSrc(_icons[key]);
            if (src != null) registerIconImage(key, src, repaint);
          }
        }
      }
    }
  }

  /// Swaps in a new [definition] and repaints — used by the designer so the
  /// live preview tracks edits. Icons are preloaded incrementally (already
  /// decoded icons are kept, so there is no flicker).
  void setDefinition(RibbonDefinition definition) {
    _def = definition;
    _preloadIcons();
    if (_state.activeTabIndex >= _def.tabs.length) {
      _state = _state.copyWith(
        activeTabIndex: (_def.tabs.length - 1).clamp(0, 9999),
      );
    }
    repaint();
  }

  String? _iconSrc(IconSource? source) {
    if (source == null) return null;
    final data = source.data;
    switch (source.kind) {
      case IconKind.svg:
        if (data.startsWith('<')) {
          final encoded = Uri.encodeComponent(data);
          return 'data:image/svg+xml;charset=utf-8,$encoded';
        }
        return data; // already a URL
      case IconKind.png:
        if (data.startsWith('http') ||
            data.startsWith('/') ||
            data.startsWith('data:'))
          return data;
        return 'data:image/png;base64,$data';
    }
  }

  // ── Pointer handling (ports Xojo MouseDown/Move/Up/Exit) ──────────────────

  void _onDown(web.MouseEvent e) {
    final p = _local(e);
    if (_layout!.hitChevron(p.$1, p.$2)) {
      _toggleCollapse();
      return;
    }
    final tab = _layout!.hitTab(p.$1, p.$2);
    if (tab != null) {
      final idx = _def.tabs.indexOf(tab.tab);
      if (idx == _state.activeTabIndex) return;
      _state = _state.copyWith(activeTabIndex: idx, hoveredTabIndex: -1);
      onEvent?.call(TabChangedEvent(idx));
      repaint();
      return;
    }
    final item = _layout!.hitItem(p.$1, p.$2);
    if (item != null && item.item.isEnabled && !item.item.isSeparator) {
      var onArrow = false;
      if (item.item.isSplitButton) {
        onArrow = item.hitArrow(p.$1, p.$2);
      }
      _state = _state.copyWith(
        pressedItemTag: item.item.tag,
        pressedOnArrow: onArrow,
      );
      repaint();
    }
  }

  void _onMove(web.MouseEvent e) {
    final p = _local(e);
    final tab = _layout!.hitTab(p.$1, p.$2);
    final item = _layout!.hitItem(p.$1, p.$2);
    final newHoveredTab = tab != null ? _def.tabs.indexOf(tab.tab) : -1;
    final newHoveredItem = item?.item.tag;
    if (newHoveredTab != _state.hoveredTabIndex ||
        newHoveredItem != _state.hoveredItemTag) {
      _state = _state.copyWith(
        hoveredTabIndex: newHoveredTab,
        hoveredItemTag: newHoveredItem,
      );
      _canvas.title = (item?.item.tooltipText ?? tab?.tab.caption ?? '').trim();
      repaint();
    }
  }

  void _onUp(web.MouseEvent e) {
    final pressedTag = _state.pressedItemTag;
    final wasOnArrow = _state.pressedOnArrow;
    if (pressedTag == null) return;
    final p = _local(e);
    _state = _state.copyWith(pressedItemTag: null);
    final laid = _layout!.hitItem(p.$1, p.$2);
    if (laid != null && laid.item.tag == pressedTag && laid.item.isEnabled) {
      _activate(laid, p, wasOnArrow);
    }
    repaint();
  }

  void _onLeave() {
    _state = _state.copyWith(
      hoveredTabIndex: -1,
      hoveredItemTag: null,
      pressedItemTag: null,
    );
    _canvas.title = '';
    repaint();
  }

  void _activate(LaidItem laid, (double, double) p, bool wasOnArrow) {
    final item = laid.item;
    if (item.itemType == RibbonItemType.dropdown && item.menuItems.isNotEmpty) {
      if (item.isSplitButton && !wasOnArrow) {
        _dispatch(ItemPressedEvent(item.tag));
      } else {
        _openMenu(laid);
      }
      return;
    }
    if (item.isToggling) {
      _def = _def.toggled(item.tag);
    }
    _dispatch(ItemPressedEvent(item.tag));
  }

  void _toggleCollapse() {
    _state = _state.copyWith(collapsed: !_state.collapsed);
    _setupCanvas();
    _dispatch(CollapseStateChangedEvent(_state.collapsed));
    repaint();
  }

  void _dispatch(RibbonEvent e) => onEvent?.call(e);

  // ── Canvas-rendered popup menu (ports DesktopMenuItem.PopUp) ──────────────

  /// Opens the dropdown menu for the active-tab item with [tag] (programmatic /
  /// demo use; normally triggered by clicking the item's arrow). No-op if the
  /// item has no menu items.
  void openMenuForTag(String tag) {
    final laid = _menuCandidate(tag);
    if (laid != null && laid.item.menuItems.isNotEmpty) _openMenu(laid);
  }

  LaidItem? _menuCandidate(String tag) {
    for (final g in _layout?.groups ?? const <LaidGroup>[]) {
      for (final i in g.items) {
        if (i.item.tag == tag) return i;
      }
    }
    return null;
  }

  void _openMenu(LaidItem laid) {
    _menu?.close();
    _menu = MenuOverlay(
      anchorCanvas: _canvas,
      anchorRect: laid.rect,
      item: laid.item,
      colors: _painter.colors,
      onSelect: (menuItemTag) {
        _dispatch(
          DropdownMenuActionEvent(
            itemTag: laid.item.tag,
            menuItemTag: menuItemTag,
          ),
        );
      },
      onDismiss: () {},
    )..show();
  }

  (double, double) _local(web.MouseEvent e) =>
      (e.offsetX.toDouble(), e.offsetY.toDouble());
}
