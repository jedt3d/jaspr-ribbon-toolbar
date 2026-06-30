import 'dart:js_interop';

import 'package:jaspr_ribbon_toolbar/web.dart';
import 'package:web/web.dart' as web;

import 'designer_logic.dart';

/// The imperative designer controller. Owns the editable [RibbonDefinition],
/// the current selection, and the live-preview [RibbonCanvasController]; renders
/// the structure tree + inspector into the shell built by `App`.
class Designer {
  Designer();

  RibbonDefinition _model = _seed();
  Selection _sel = const Selection(0);
  RibbonCanvasController? _preview;
  final Map<String, String> _icons = {
    // Seeded demo icons (real SVG assets under web/icons/).
    'paste': 'icons/paste.svg',
    'cut': 'icons/cut.svg',
    'copy': 'icons/copy.svg',
    'delete': 'icons/delete.svg',
  };
  _Drag? _drag;

  // Cached shell elements.
  late final web.HTMLDivElement _tree;
  late final web.HTMLDivElement _inspector;
  late final web.HTMLDivElement _previewHost;
  late final web.HTMLDivElement _iconLib;
  late final web.HTMLSelectElement _addType;
  late final web.HTMLElement _status;

  void start() {
    _tree = web.document.getElementById('tree') as web.HTMLDivElement;
    _inspector = web.document.getElementById('inspector') as web.HTMLDivElement;
    _previewHost =
        web.document.getElementById('preview-host') as web.HTMLDivElement;
    _iconLib =
        web.document.getElementById('icon-library') as web.HTMLDivElement;
    _addType = web.document.getElementById('add-type') as web.HTMLSelectElement;
    _status = web.document.getElementById('status') as web.HTMLElement;

    // Live preview canvas + controller, sized to fit the panel.
    final w = _previewWidth();
    final canvas = web.HTMLCanvasElement()
      ..id = 'preview-canvas'
      ..width = w.round()
      ..height = 118;
    _previewHost.append(canvas);
    _preview = RibbonCanvasController(
      canvas: canvas,
      definition: _model,
      colors: RibbonColors.light,
      icons: _buildRegistry(),
      onEvent: (e) {
        if (e is TabChangedEvent) {
          _sel = Selection(e.tabIndex);
          _renderTree();
          _renderInspector();
        }
      },
    )..attach();

    // Wire the toolbar + menu actions.
    _onClick('btn-add', _addSelected);
    _onClick('btn-delete', _deleteSelected);
    _onClick('btn-new', _newRibbon);
    _onClick('btn-save', _saveRibbon);
    _onClick('btn-load', _openRibbon);
    _onClick('btn-upload-icon', _uploadIcons);

    // Keep the preview fitted when the window resizes.
    web.window.addEventListener(
      'resize',
      ((web.Event _) => _fitPreview()).toJS,
    );

    refresh();
  }

  double _previewWidth() =>
      (_previewHost.clientWidth - 12).clamp(280, 1600).toDouble();

  void _fitPreview() {
    final p = _preview;
    if (p == null) return;
    p.resize(_previewWidth(), 118);
  }

  void refresh() {
    _renderTree();
    _renderInspector();
    _renderIconLibrary();
    _preview?.setIcons(_buildRegistry());
    _preview?.setDefinition(_model);
    _revealContextual();
  }

  /// Like [refresh] but leaves the inspector DOM untouched — used while typing
  /// into an inspector text field so the focused `<input>` keeps focus.
  void quietRefresh() {
    _renderTree();
    _renderIconLibrary();
    _preview?.setIcons(_buildRegistry());
    _preview?.setDefinition(_model);
    _revealContextual();
  }

  /// Shows every contextual tab in the preview so the designer can display them.
  void _revealContextual() {
    for (final tab in _model.tabs) {
      if (tab.isContextual && tab.contextGroup != null) {
        _preview?.showContextGroup(tab.contextGroup!);
      }
    }
  }

  // ── Icon asset management ────────────────────────────────────────────────

  IconRegistry _buildRegistry() {
    final map = <String, IconSource>{};
    for (final entry in _icons.entries) {
      final src = entry.value;
      final isSvg = src.endsWith('.svg') || src.contains('image/svg');
      map[entry.key] = isSvg ? IconSource.svg(src) : IconSource.png(src);
    }
    return IconRegistry.assets(map);
  }

  void _uploadIcons() {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.svg,.png,image/svg+xml,image/png'
      ..multiple = true;
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null) return;
      final reader = web.FileReader();
      var loaded = 0;
      void readNext(int i) {
        if (i >= files.length) {
          refresh();
          _status.textContent = 'Loaded $loaded icon(s).';
          return;
        }
        final f = files.item(i);
        if (f == null) {
          readNext(i + 1);
          return;
        }
        reader.onLoadEnd.first.then((_) {
          var key = _deriveIconKey(f.name);
          key = _uniqueIconKey(key);
          _icons[key] = reader.result as String;
          loaded++;
          readNext(i + 1);
        });
        reader.readAsDataURL(f);
      }

      readNext(0);
    });
    input.click();
  }

  /// Derives a valid icon key (`[a-z.]`) from a filename.
  String _deriveIconKey(String filename) => deriveIconKey(filename);

  void _deleteIcon(String key) {
    _icons.remove(key);
    refresh();
    _status.textContent = 'Removed icon "$key".';
  }

  /// Assigns [key] to the currently-selected item (if any).
  void _assignIcon(String key) {
    if (_sel.ii == null) {
      _status.textContent = 'Select an item first to assign an icon.';
      return;
    }
    _updateItem(
      _sel.ti,
      _sel.gi!,
      _sel.ii!,
      (it) => it.copyWith(iconKey: key),
      rebuildInspector: false,
    );
    _status.textContent = 'Assigned "$key" to selected item.';
  }

  /// Inline-renames an icon key. Validates to `[a-z.]`; rejects collisions.
  void _renameIcon(String oldKey, web.HTMLSpanElement label) {
    final src = _icons[oldKey];
    if (src == null) return;
    final input = web.HTMLInputElement()
      ..type = 'text'
      ..value = oldKey
      ..className = 'rename';
    label.replaceWith(input);
    input.focus();
    input.select();
    void commit() {
      final nv = _sanitizeKey(input.value);
      if (nv.isEmpty || nv == oldKey) {
        input.replaceWith(label);
        return;
      }
      if (_icons.containsKey(nv)) {
        _status.textContent = 'Name "$nv" already exists — not renamed.';
        input.replaceWith(label);
        return;
      }
      _icons.remove(oldKey);
      _icons[nv] = src;
      _model = _retargetIcon(oldKey, nv);
      _status.textContent = 'Renamed "$oldKey" → "$nv".';
      refresh();
    }

    void cancel() => input.replaceWith(label);
    input.onBlur.listen((_) => commit());
    input.onKeyDown.listen((e) {
      if (e.key == 'Enter') {
        e.preventDefault();
        commit();
      } else if (e.key == 'Escape') {
        e.preventDefault();
        cancel();
      }
    });
  }

  /// Returns a copy of the model with every `iconKey == oldKey` updated to [newKey].
  RibbonDefinition _retargetIcon(String oldKey, String newKey) =>
      retargetIcon(_model, oldKey, newKey);

  void _renderIconLibrary() {
    _iconLib.textContent = '';
    if (_icons.isEmpty) {
      _iconLib.append(_empty('No icons yet — upload SVG/PNG.'));
      return;
    }
    final assignedKey = _selectedItem()?.iconKey;
    final keys = _icons.keys.toList()..sort();
    for (final key in keys) {
      final card = web.HTMLDivElement()
        ..className = 'icon-card${key == assignedKey ? ' assigned' : ''}';
      final img = web.HTMLImageElement()
        ..src = _icons[key] ?? ''
        ..style.background = '#f3f4f6';
      card.append(img);
      final label = web.HTMLSpanElement()
        ..className = 'key'
        ..textContent = key
        ..title = 'Click to rename';
      label.onClick.listen((e) {
        e.stopPropagation();
        _renameIcon(key, label);
      });
      card.append(label);
      card.title = 'Click card to assign; click name to rename';
      card.onClick.listen((_) => _assignIcon(key));
      final del = web.HTMLSpanElement()
        ..className = 'del'
        ..textContent = '✕'
        ..title = 'Remove';
      del.onClick.listen((e) {
        e.stopPropagation();
        _deleteIcon(key);
      });
      card.append(del);
      _iconLib.append(card);
    }
  }

  RibbonItem? _selectedItem() {
    if (_sel.ii == null || _sel.gi == null) return null;
    if (_sel.ti < 0 || _sel.ti >= _model.tabs.length) return null;
    final tab = _model.tabs[_sel.ti];
    if (_sel.gi! < 0 || _sel.gi! >= tab.groups.length) return null;
    final group = tab.groups[_sel.gi!];
    if (_sel.ii! < 0 || _sel.ii! >= group.items.length) return null;
    return group.items[_sel.ii!];
  }

  // ── Structure tree ────────────────────────────────────────────────────────

  void _renderTree() {
    _tree.textContent = '';
    if (_model.tabs.isEmpty) {
      _tree.append(_empty('No tabs yet — add one above.'));
      return;
    }
    for (var ti = 0; ti < _model.tabs.length; ti++) {
      final tab = _model.tabs[ti];
      _tree.append(
        _row(
          0,
          ti,
          0,
          tab.caption,
          tab.isContextual ? 'Contextual tab' : 'Tab',
          tab.contextGroup ?? '',
        ),
      );
      for (var gi = 0; gi < tab.groups.length; gi++) {
        final group = tab.groups[gi];
        _tree.append(_row(1, ti, gi, group.caption, 'Group', ''));
        for (var ii = 0; ii < group.items.length; ii++) {
          final item = group.items[ii];
          final cap = item.isSeparator ? '— separator —' : item.caption;
          _tree.append(
            _row(
              2,
              ti,
              gi,
              cap,
              item.jsonType,
              item.isSeparator ? '' : item.tag,
              itemIndex: ii,
            ),
          );
        }
      }
    }
  }

  web.HTMLDivElement _row(
    int level,
    int ti,
    int gi,
    String caption,
    String type,
    String tag, {
    int? itemIndex,
  }) {
    final isSel =
        _sel.ti == ti &&
        _sel.gi == (level <= 1 ? null : gi) &&
        _sel.ii == itemIndex;
    final r = web.HTMLDivElement()
      ..className = 'tree-row l$level${isSel ? ' selected' : ''}'
      ..style.marginLeft = '${level * 16}px'
      ..draggable = true;
    r.append(_span(caption, cls: 'cap'));
    r.append(_span(type, cls: 'badge'));
    if (tag.isNotEmpty) r.append(_span(tag, cls: 'tag'));
    final drag = _Drag(level, ti, gi: level >= 1 ? gi : null, ii: itemIndex);
    r.onDragStart.listen((_) {
      _drag = drag;
    });
    r.onDragOver.listen((e) => e.preventDefault());
    r.onDrop.listen((e) {
      e.preventDefault();
      _handleDrop(drag);
    });
    r.onClick.listen((_) {
      _sel = Selection(ti, gi: level >= 1 ? gi : null, ii: itemIndex);
      _renderTree();
      _renderInspector();
    });
    return r;
  }

  // ── Inspector ─────────────────────────────────────────────────────────────

  void _renderInspector() {
    _inspector.textContent = '';
    if (_sel.ti < 0 || _sel.ti >= _model.tabs.length) {
      _inspector.append(_empty('Select a node to edit its properties.'));
      return;
    }
    final tab = _model.tabs[_sel.ti];
    if (_sel.isTab) {
      _inspector.append(
        _textField(
          'Caption',
          tab.caption,
          (v) => _updateTab(
            _sel.ti,
            (t) => _rebuildTab(t, caption: v),
            rebuildInspector: false,
          ),
        ),
      );
      _inspector.append(
        _checkField('Contextual tab', tab.isContextual, (v) {
          _updateTab(_sel.ti, (t) => _rebuildTab(t, isContextual: v));
        }),
      );
      if (tab.isContextual) {
        _inspector.append(
          _textField(
            'Context group',
            tab.contextGroup ?? '',
            (v) => _updateTab(
              _sel.ti,
              (t) => _rebuildTab(t, contextGroup: v),
              rebuildInspector: false,
            ),
          ),
        );
        _inspector.append(
          _colorField(
            'Accent color',
            tab.accentColor ?? 0xFF2E7D32,
            (v) => _updateTab(
              _sel.ti,
              (t) => _rebuildTab(t, accentColor: v),
              rebuildInspector: false,
            ),
          ),
        );
      }
      _status.textContent = 'Selected tab "${tab.caption}"';
      return;
    }
    final gi = _sel.gi!;
    if (gi < 0 || gi >= tab.groups.length) {
      _inspector.append(_empty('Select a node to edit its properties.'));
      return;
    }
    final group = tab.groups[gi];
    if (_sel.isGroup) {
      _inspector.append(
        _textField(
          'Caption',
          group.caption,
          (v) => _updateGroup(
            _sel.ti,
            gi,
            (g) => g.copyWith(caption: v),
            rebuildInspector: false,
          ),
        ),
      );
      _status.textContent = 'Selected group "${group.caption}"';
      return;
    }
    // Item
    final ii = _sel.ii!;
    final item = group.items[ii];
    _inspector.append(
      _textField(
        'Caption',
        item.caption,
        (v) => _updateItem(
          _sel.ti,
          gi,
          ii,
          (it) => it.copyWith(caption: v),
          rebuildInspector: false,
        ),
      ),
    );
    _inspector.append(
      _textField(
        'Tag',
        item.tag,
        (v) => _updateItem(
          _sel.ti,
          gi,
          ii,
          (it) => it.copyWith(tag: v),
          rebuildInspector: false,
        ),
        sanitize: _sanitizeKey,
        hint: 'lowercase letters and dots only',
      ),
    );
    // Icon key — dropdown of registered icons (+ none).
    final iconKeys = _icons.keys.toList()..sort();
    _inspector.append(
      _selectField(
        'Icon key',
        item.iconKey ?? '',
        ['', ...iconKeys],
        (v) => _updateItem(
          _sel.ti,
          gi,
          ii,
          (it) => it.copyWith(iconKey: v.isEmpty ? null : v),
          rebuildInspector: false,
        ),
        blankLabel: '— none —',
      ),
    );
    _inspector.append(
      _textField(
        'Tooltip',
        item.tooltipText ?? '',
        (v) => _updateItem(
          _sel.ti,
          gi,
          ii,
          (it) => it.copyWith(tooltipText: v.isEmpty ? null : v),
          rebuildInspector: false,
        ),
      ),
    );
    _inspector.append(
      _selectField('Item type', item.jsonType, _itemTypes, (v) {
        _updateItem(_sel.ti, gi, ii, (it) => _rebuildAs(it, v));
      }),
    );
    _inspector.append(
      _checkField(
        'Is enabled',
        item.isEnabled,
        (v) => _updateItem(
          _sel.ti,
          gi,
          ii,
          (it) => it.copyWith(isEnabled: v),
          rebuildInspector: false,
        ),
      ),
    );
    if (item.isToggling) {
      _inspector.append(
        _checkField(
          item.itemType == RibbonItemType.checkBox ? 'Checked' : 'Active',
          item.isToggleActive,
          (v) => _updateItem(
            _sel.ti,
            gi,
            ii,
            (it) => it.copyWith(isToggleActive: v),
            rebuildInspector: false,
          ),
        ),
      );
    }
    if (item.itemType == RibbonItemType.dropdown) {
      _inspector.append(_menuItemsEditor(_sel.ti, gi, ii, item));
    }
    _status.textContent = 'Selected ${item.jsonType} "${item.caption}"';
  }

  static const List<String> _itemTypes = [
    'large',
    'small',
    'dropdown',
    'splitbutton',
    'toggle',
    'checkbox',
    'separator',
  ];

  RibbonItem _rebuildAs(RibbonItem it, String type) => rebuildItemAs(it, type);

  web.HTMLElement _menuItemsEditor(int ti, int gi, int ii, RibbonItem item) {
    final wrap = web.HTMLDivElement()..className = 'field';
    wrap.append(_label('Menu items'));
    for (var mi = 0; mi < item.menuItems.length; mi++) {
      final m = item.menuItems[mi];
      final row = web.HTMLDivElement()..className = 'mi-row';
      final cap = _input(m.caption);
      final tag = _input(m.tag);
      cap.onInput.listen(
        (_) => _mutateMenuItem(ti, gi, ii, mi, cap.value, tag.value),
      );
      tag.onInput.listen((_) {
        final s = _sanitizeKey(tag.value);
        if (s != tag.value) tag.value = s;
        _mutateMenuItem(ti, gi, ii, mi, cap.value, s);
      });
      final del = _btn('✕')
        ..onClick.listen((_) {
          _updateItem(ti, gi, ii, (it) {
            final list = List<RibbonMenuItem>.of(it.menuItems)..removeAt(mi);
            return it.copyWith(menuItems: list);
          }, rebuildInspector: false);
        });
      row.append(cap);
      row.append(tag);
      row.append(del);
      wrap.append(row);
    }
    wrap.append(
      _btn('+ Add menu item')
        ..className = 'btn'
        ..onClick.listen((_) {
          _updateItem(ti, gi, ii, (it) {
            final list = List<RibbonMenuItem>.of(it.menuItems)
              ..add(const RibbonMenuItem(caption: 'New item', tag: 'new.item'));
            return it.copyWith(menuItems: list);
          });
        }),
    );
    return wrap;
  }

  void _mutateMenuItem(int ti, int gi, int ii, int mi, String cap, String tag) {
    _updateItem(ti, gi, ii, (it) {
      final list = List<RibbonMenuItem>.of(it.menuItems);
      list[mi] = list[mi].copyWith(caption: cap, tag: tag);
      return it.copyWith(menuItems: list);
    }, rebuildInspector: false);
  }

  // ── Mutations on the immutable model ─────────────────────────────────────

  void _updateTab(
    int ti,
    RibbonTab Function(RibbonTab) fn, {
    bool rebuildInspector = true,
  }) {
    final tabs = List<RibbonTab>.of(_model.tabs);
    tabs[ti] = fn(tabs[ti]);
    _model = _model.copyWith(tabs: tabs);
    if (rebuildInspector) {
      refresh();
    } else {
      quietRefresh();
    }
  }

  void _updateGroup(
    int ti,
    int gi,
    RibbonGroup Function(RibbonGroup) fn, {
    bool rebuildInspector = true,
  }) => _updateTab(ti, (t) {
    final groups = List<RibbonGroup>.of(t.groups);
    groups[gi] = fn(groups[gi]);
    return t.copyWith(groups: groups);
  }, rebuildInspector: rebuildInspector);

  void _updateItem(
    int ti,
    int gi,
    int ii,
    RibbonItem Function(RibbonItem) fn, {
    bool rebuildInspector = true,
  }) => _updateGroup(ti, gi, (g) {
    final items = List<RibbonItem>.of(g.items);
    items[ii] = fn(items[ii]);
    return g.copyWith(items: items);
  }, rebuildInspector: rebuildInspector);

  // ── Add / Delete ─────────────────────────────────────────────────────────

  void _addSelected() {
    final type = _addType.value;
    if (type == 'tab') {
      final tab = const RibbonTab(caption: 'New tab', groups: []);
      _model = _model.copyWith(tabs: [..._model.tabs, tab]);
      _sel = Selection(_model.tabs.length - 1);
    } else if (type == 'group') {
      final ti = _sel.ti.clamp(0, _model.tabs.length - 1);
      _addGroup(ti, const RibbonGroup(caption: 'New group', items: []));
      _sel = Selection(ti, gi: _model.tabs[ti].groups.length - 1);
    } else {
      final ti = _sel.ti.clamp(0, _model.tabs.length - 1);
      final gi = (_sel.gi ?? (_model.tabs[ti].groups.length - 1)).clamp(
        0,
        _model.tabs[ti].groups.length - 1,
      );
      final item = _newItem(type);
      _addItem(ti, gi, item);
      _sel = Selection(
        ti,
        gi: gi,
        ii: _model.tabs[ti].groups[gi].items.length - 1,
      );
    }
    refresh();
    _status.textContent = 'Added $type.';
  }

  RibbonItem _newItem(String type) {
    switch (type) {
      case 'small':
        return RibbonItem.small(caption: 'New', tag: 'new');
      case 'dropdown':
        return RibbonItem.dropdown(caption: 'New', tag: 'new');
      case 'splitbutton':
        return RibbonItem.splitButton(caption: 'New', tag: 'new');
      case 'toggle':
        return RibbonItem.toggle(caption: 'New', tag: 'new');
      case 'checkbox':
        return RibbonItem.checkBox(caption: 'New', tag: 'new');
      case 'separator':
        return const RibbonItem.separator();
      default:
        return RibbonItem.large(caption: 'New', tag: 'new');
    }
  }

  void _addGroup(int ti, RibbonGroup group) =>
      _updateTab(ti, (t) => t.copyWith(groups: [...t.groups, group]));

  void _addItem(int ti, int gi, RibbonItem item) =>
      _updateGroup(ti, gi, (g) => g.copyWith(items: [...g.items, item]));

  void _deleteSelected() {
    if (_sel.ii != null) {
      _updateGroup(_sel.ti, _sel.gi!, (g) {
        final items = List<RibbonItem>.of(g.items)..removeAt(_sel.ii!);
        return g.copyWith(items: items);
      });
      _sel = Selection(_sel.ti, gi: _sel.gi);
    } else if (_sel.gi != null) {
      _updateTab(_sel.ti, (t) {
        final groups = List<RibbonGroup>.of(t.groups)..removeAt(_sel.gi!);
        return t.copyWith(groups: groups);
      });
      _sel = Selection(_sel.ti);
    } else {
      final tabs = List<RibbonTab>.of(_model.tabs)..removeAt(_sel.ti);
      _model = _model.copyWith(tabs: tabs);
      _sel = Selection((_model.tabs.length - 1).clamp(0, 9999));
    }
    refresh();
    _status.textContent = 'Deleted.';
  }

  // ── Drag-to-reorder (same level only) ─────────────────────────────────────

  void _handleDrop(_Drag target) {
    final d = _drag;
    _drag = null;
    if (d == null || d.level != target.level) return;
    if (d.level == 0) {
      _reorderTabs(d.ti, target.ti);
    } else if (d.level == 1) {
      if (d.ti != target.ti || d.gi == null || target.gi == null) return;
      _reorderGroups(d.ti, d.gi!, target.gi!);
    } else {
      if (d.ti != target.ti ||
          d.gi != target.gi ||
          d.ii == null ||
          target.ii == null)
        return;
      _reorderItems(d.ti, d.gi!, d.ii!, target.ii!);
    }
  }

  void _reorderTabs(int from, int to) {
    if (from == to) return;
    final tabs = List<RibbonTab>.of(_model.tabs);
    final moved = tabs.removeAt(from);
    final at = (from < to ? to - 1 : to).clamp(0, tabs.length);
    tabs.insert(at, moved);
    _model = _model.copyWith(tabs: tabs);
    _sel = Selection(at);
    refresh();
    _status.textContent = 'Moved tab.';
  }

  void _reorderGroups(int ti, int from, int to) {
    if (from == to) return;
    _updateTab(ti, (t) {
      final groups = List<RibbonGroup>.of(t.groups);
      final moved = groups.removeAt(from);
      final at = (from < to ? to - 1 : to).clamp(0, groups.length);
      groups.insert(at, moved);
      return t.copyWith(groups: groups);
    });
    final at = (from < to ? to - 1 : to).clamp(0, 9999);
    _sel = Selection(ti, gi: at);
    refresh();
    _status.textContent = 'Moved group.';
  }

  void _reorderItems(int ti, int gi, int from, int to) {
    if (from == to) return;
    _updateGroup(ti, gi, (g) {
      final items = List<RibbonItem>.of(g.items);
      final moved = items.removeAt(from);
      final at = (from < to ? to - 1 : to).clamp(0, items.length);
      items.insert(at, moved);
      return g.copyWith(items: items);
    });
    final at = (from < to ? to - 1 : to).clamp(0, 9999);
    _sel = Selection(ti, gi: gi, ii: at);
    refresh();
    _status.textContent = 'Moved item.';
  }

  // ── New / Save / Open ────────────────────────────────────────────────────

  void _newRibbon() {
    _model = const RibbonDefinition(
      version: '2.0',
      projectType: 'web',
      tabs: [
        RibbonTab(
          caption: 'Home',
          groups: [RibbonGroup(caption: 'New group', items: [])],
        ),
      ],
    );
    _sel = const Selection(0);
    refresh();
    _status.textContent = 'New ribbon.';
  }

  void _saveRibbon() {
    // Embed the current icon library into the bundle so it is self-contained.
    _model = _model.copyWith(icons: _buildAssetMap());
    final json = _model.toJsonString();
    final blob = web.Blob(
      <JSAny>[json.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.HTMLAnchorElement()
      ..href = url
      ..download = 'ribbon.bundle.json';
    web.document.body!.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
    _status.textContent = 'Saved ribbon.bundle.json (${_icons.length} icons).';
  }

  /// Builds the model-side icon map from the runtime library (key → src),
  /// inferring each asset's kind.
  Map<String, IconAsset> _buildAssetMap() => {
    for (final entry in _icons.entries)
      entry.key: IconAsset(
        kind: IconAssetKind.infer(entry.value),
        data: entry.value,
      ),
  };

  void _openRibbon() {
    final input = web.HTMLInputElement()..type = 'file';
    input.accept = '.json,.ribbon,application/json';
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.length == 0) return;
      final reader = web.FileReader();
      reader.onLoadEnd.listen((_) {
        try {
          final src = reader.result as String;
          _model = RibbonDefinition.fromJsonString(src);
          // Restore the icon library from the embedded bundle assets.
          _icons
            ..clear()
            ..addAll({
              for (final e in _model.icons.entries) e.key: e.value.data,
            });
          _sel = const Selection(0);
          refresh();
          _status.textContent =
              'Opened ribbon (${_model.tabs.length} tabs, ${_icons.length} icons).';
        } catch (e) {
          _status.textContent = 'Open failed: $e';
        }
      });
      reader.readAsText(files.item(0)!);
    });
    input.click();
  }

  // ── DOM helpers ──────────────────────────────────────────────────────────

  void _onClick(String id, void Function() fn) {
    (web.document.getElementById(id) as web.HTMLButtonElement).onClick.listen(
      (_) => fn(),
    );
  }

  web.HTMLSpanElement _span(String text, {String? cls}) {
    final s = web.HTMLSpanElement()..textContent = text;
    if (cls != null) s.className = cls;
    return s;
  }

  web.HTMLDivElement _empty(String text) {
    final d = web.HTMLDivElement()..className = 'empty';
    d.textContent = text;
    return d;
  }

  web.HTMLDivElement _label(String text) {
    final f = web.HTMLDivElement()..className = 'field';
    final l = web.HTMLLabelElement()..textContent = text;
    f.append(l);
    return f;
  }

  web.HTMLDivElement _textField(
    String label,
    String value,
    void Function(String) onChange, {
    String Function(String)? sanitize,
    String? hint,
  }) {
    final f = web.HTMLDivElement()..className = 'field';
    final l = web.HTMLLabelElement()
      ..textContent = hint == null ? label : '$label ($hint)'
      ..htmlFor = 'f-$label';
    final input = _input(value)..id = 'f-$label';
    input.onInput.listen((_) {
      var v = input.value;
      if (sanitize != null) {
        final s = sanitize(v);
        if (s != v) {
          input.value = s;
          v = s;
        }
      }
      onChange(v);
    });
    f.append(l);
    f.append(input);
    return f;
  }

  /// Allows only lowercase letters and dots (`[a-z.]`) — the rule for tags and
  /// icon names. Invalid characters are dropped as you type.
  String _sanitizeKey(String s) => sanitizeKey(s);

  /// Returns [base] or `base.1`, `base.2`, … until it is not already an icon key.
  String _uniqueIconKey(String base) => uniqueIconKey(base, _icons.keys);

  web.HTMLDivElement _selectField(
    String label,
    String value,
    List<String> options,
    void Function(String) onChange, {
    String? blankLabel,
  }) {
    final f = web.HTMLDivElement()..className = 'field';
    final l = web.HTMLLabelElement()..textContent = label;
    final sel = web.HTMLSelectElement();
    for (final o in options) {
      final opt = web.HTMLOptionElement()
        ..textContent = (o.isEmpty ? (blankLabel ?? '—') : o)
        ..value = o;
      if (o == value) opt.selected = true;
      sel.append(opt);
    }
    sel.onChange.listen((_) => onChange(sel.value));
    f.append(l);
    f.append(sel);
    return f;
  }

  web.HTMLDivElement _colorField(
    String label,
    int argb,
    void Function(int) onChange,
  ) {
    final f = web.HTMLDivElement()..className = 'field';
    final l = web.HTMLLabelElement()..textContent = label;
    final hex =
        '#${((argb >> 16) & 0xFF).toRadixString(16).padLeft(2, '0')}'
        '${((argb >> 8) & 0xFF).toRadixString(16).padLeft(2, '0')}'
        '${(argb & 0xFF).toRadixString(16).padLeft(2, '0')}';
    final input = web.HTMLInputElement()
      ..type = 'color'
      ..value = hex;
    input.onChange.listen((_) {
      final v = input.value;
      final r = int.parse(v.substring(1, 3), radix: 16);
      final g = int.parse(v.substring(3, 5), radix: 16);
      final b = int.parse(v.substring(5, 7), radix: 16);
      onChange((0xFF << 24) | (r << 16) | (g << 8) | b);
    });
    l.append(input);
    f.append(l);
    return f;
  }

  /// Rebuilds a tab preserving its groups, toggling/setting contextual fields.
  /// (`RibbonTab` is immutable with two constructors, so contextual changes
  /// require reconstruction.)
  RibbonTab _rebuildTab(
    RibbonTab t, {
    String? caption,
    bool? isContextual,
    String? contextGroup,
    int? accentColor,
  }) => rebuildTab(
    t,
    caption: caption,
    isContextual: isContextual,
    contextGroup: contextGroup,
    accentColor: accentColor,
  );

  web.HTMLDivElement _checkField(
    String label,
    bool value,
    void Function(bool) onChange,
  ) {
    final f = web.HTMLDivElement()..className = 'field';
    final input = web.HTMLInputElement()
      ..type = 'checkbox'
      ..checked = value;
    input.onChange.listen((_) => onChange(input.checked));
    final l = web.HTMLLabelElement();
    l.append(input);
    l.append(_span(' $label'));
    f.append(l);
    return f;
  }

  web.HTMLInputElement _input(String value) {
    return web.HTMLInputElement()
      ..type = 'text'
      ..value = value;
  }

  web.HTMLButtonElement _btn(String label) {
    return web.HTMLButtonElement()..textContent = label;
  }
}

/// A dragged tree node address (for drag-to-reorder).
class _Drag {
  const _Drag(this.level, this.ti, {this.gi, this.ii});
  final int level;
  final int ti;
  final int? gi;
  final int? ii;
}

/// A selected node address: [ti] always set; [gi]/[ii] set when drilling into a
/// group/item.
class Selection {
  const Selection(this.ti, {this.gi, this.ii});
  final int ti;
  final int? gi;
  final int? ii;

  bool get isTab => gi == null;
  bool get isGroup => gi != null && ii == null;
}

RibbonDefinition _seed() => RibbonDefinition(
  version: '2.0',
  projectType: 'web',
  tabs: [
    RibbonTab(
      caption: 'Home',
      groups: [
        RibbonGroup(
          caption: 'Clipboard',
          items: [
            RibbonItem.large(
              caption: 'Paste',
              tag: 'home.paste',
              iconKey: 'paste',
            ),
            RibbonItem.small(caption: 'Cut', tag: 'home.cut', iconKey: 'cut'),
            RibbonItem.small(
              caption: 'Copy',
              tag: 'home.copy',
              iconKey: 'copy',
            ),
          ],
        ),
      ],
    ),
  ],
);
