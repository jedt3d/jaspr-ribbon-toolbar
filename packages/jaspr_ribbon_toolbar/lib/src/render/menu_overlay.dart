import 'dart:async';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import '../model/menu_item.dart';
import '../model/ribbon_item.dart';
import '../theme/ribbon_colors.dart';
import 'ribbon_geometry.dart';
import 'web_canvas_surface.dart';

/// A canvas-rendered popup menu for dropdown / split-button items — the Jaspr
/// counterpart of Xojo's `DesktopMenuItem.PopUp` (desktop) and the JS-injected
/// menu overlay (web), but painted into its own `<canvas>` so it stays
/// consistent with the ribbon.
///
/// The overlay is anchored below the button's bottom-left corner. If there is
/// no room below it flips above; if it would overflow the right edge it shifts
/// left. A transparent fullscreen backdrop closes the menu on outside click.
class MenuOverlay {
  MenuOverlay({
    required web.HTMLCanvasElement anchorCanvas,
    required RRect anchorRect,
    required RibbonItem item,
    required RibbonColors colors,
    required void Function(String menuItemTag) onSelect,
    required void Function() onDismiss,
  }) : _anchor = anchorCanvas,
       _anchorRect = anchorRect,
       _item = item,
       _colors = colors,
       _onSelect = onSelect,
       _onDismiss = onDismiss;

  final web.HTMLCanvasElement _anchor;
  final RRect _anchorRect;
  final RibbonItem _item;
  final RibbonColors _colors;
  final void Function(String menuItemTag) _onSelect;
  final void Function() _onDismiss;

  late final web.HTMLCanvasElement _canvas;
  late final web.HTMLDivElement _backdrop;
  late final WebCanvasSurface _surface;
  late final double _menuW;
  late final double _menuH;
  late final List<_MenuRow> _rows;
  final List<StreamSubscription<dynamic>> _subs = [];
  int _hover = -1;
  bool _closed = false;

  static const double _padX = 12;
  static const double _padY = 5;
  static const double _rowH = 26;
  static const double _sepH = 9;
  static const double _minW = 170;
  static const double _maxW = 300;

  /// Builds, positions, paints and shows the overlay.
  void show() {
    // Build the overlay canvas + context first so we can measure text.
    _canvas = web.HTMLCanvasElement();
    final ctx = _canvas.getContext('2d');
    if (ctx == null) return;
    _surface = WebCanvasSurface(ctx as web.CanvasRenderingContext2D);

    // Lay out rows + compute size.
    _rows = [];
    var y = _padY;
    var maxTextW = 0.0;
    _surface.setFont(size: 12);
    for (final mi in _item.menuItems) {
      if (mi.isSeparator) {
        _rows.add(_MenuRow.separator(y));
        y += _sepH;
      } else {
        final w = _surface.measureTextWidth(mi.caption);
        if (w > maxTextW) maxTextW = w;
        _rows.add(_MenuRow.item(mi, y, _rowH));
        y += _rowH;
      }
    }
    _menuW = (maxTextW + _padX * 2).clamp(_minW, _maxW);
    _menuH = y + _padY;

    // Position in the viewport, anchored to the button's bottom-left.
    final a = _anchor.getBoundingClientRect();
    final dpr = web.window.devicePixelRatio.clamp(1.0, 3.0);
    var left = a.left + _anchorRect.x;
    var top = a.top + _anchorRect.bottom + 2;
    // Flip above if it would overflow the bottom.
    if (top + _menuH > web.window.innerHeight) {
      final above = a.top + _anchorRect.y - _menuH - 2;
      if (above > 4) top = above;
    }
    // Clamp into the viewport horizontally.
    left = (left).clamp(4.0, math.max(4.0, web.window.innerWidth - _menuW - 4));

    // Size the backing store for HiDPI and place the element.
    _canvas.width = (_menuW * dpr).round();
    _canvas.height = (_menuH * dpr).round();
    _canvas.style
      ..position = 'fixed'
      ..left = '${left}px'
      ..top = '${top}px'
      ..width = '${_menuW}px'
      ..height = '${_menuH}px'
      ..zIndex = '99999'
      ..borderRadius = '6px'
      ..boxShadow = '0 6px 18px rgba(0,0,0,0.18)';
    _surface.ctx.scale(dpr, dpr);

    // Fullscreen transparent backdrop to catch outside clicks.
    _backdrop = web.HTMLDivElement();
    _backdrop.style
      ..position = 'fixed'
      ..left = '0'
      ..top = '0'
      ..width = '100%'
      ..height = '100%'
      ..zIndex = '99998';
    _backdrop.onClick.listen((_) => dismiss());

    _subs.add(_canvas.onMouseMove.listen(_onMove));
    _subs.add(
      _canvas.onMouseLeave.listen((_) {
        _hover = -1;
        _paint();
      }),
    );
    _subs.add(_canvas.onMouseDown.listen(_onDown));

    _paint();
    web.document.body!.append(_backdrop);
    web.document.body!.append(_canvas);
  }

  void _onMove(web.MouseEvent e) {
    final idx = _rowAt(e.offsetY.toDouble());
    if (idx != _hover) {
      _hover = idx;
      _paint();
    }
  }

  void _onDown(web.MouseEvent e) {
    final idx = _rowAt(e.offsetY.toDouble());
    if (idx >= 0 && idx < _rows.length) {
      final row = _rows[idx];
      if (row.isItem) {
        _onSelect(row.menuItem!.tag);
        close();
      }
    }
  }

  int _rowAt(double y) {
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (y >= r.y && y < r.y + r.h) return i;
    }
    return -1;
  }

  /// Closes the menu without a selection (outside click / dismiss).
  void dismiss() {
    _onDismiss();
    close();
  }

  /// Tears down the overlay (canvas + backdrop + listeners).
  void close() {
    if (_closed) return;
    _closed = true;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _canvas.remove();
    _backdrop.remove();
  }

  void _paint() {
    final c = _surface.ctx;
    c.clearRect(0, 0, _menuW, _menuH);
    // Panel background + border.
    _surface.setFill(RibbonColors.toCssHex(_colors.contentBackground));
    _surface.fillRoundRect(0.5, 0.5, _menuW - 1, _menuH - 1, 6);
    _surface.setStroke(RibbonColors.toCssHex(_colors.border));
    _surface.setLineWidth(1);
    _surface.strokeRoundRect(0.5, 0.5, _menuW - 1, _menuH - 1, 6);
    // Rows.
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (r.isSeparator) {
        _surface.setFill(RibbonColors.toCssHex(_colors.groupSeparator));
        _surface.fillRect(_padX, r.y + _sepH / 2, _menuW - _padX * 2, 1);
        continue;
      }
      if (i == _hover) {
        _surface.setFill(RibbonColors.toCssHex(_colors.itemHoverBackground));
        _surface.fillRoundRect(3, r.y, _menuW - 6, r.h - 2, 4);
      }
      _surface.setFill(RibbonColors.toCssHex(_colors.itemText));
      _surface.setFont(size: 12);
      _surface.fillText(r.menuItem!.caption, _padX, r.y + r.h - 8);
    }
  }
}

class _MenuRow {
  _MenuRow.item(this.menuItem, this.y, this.h) : isSeparator = false;
  _MenuRow.separator(this.y) : menuItem = null, h = 9, isSeparator = true;

  final RibbonMenuItem? menuItem;
  final double y;
  final double h;
  final bool isSeparator;

  bool get isItem => !isSeparator;
}
