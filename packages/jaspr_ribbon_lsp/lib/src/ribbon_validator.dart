import 'dart:convert';

/// Severity of a [RibbonDiagnostic], mirroring LSP's `DiagnosticSeverity`.
enum RibbonSeverity { error, warning, information, hint }

/// A single problem found while validating a `.ribbon` document.
class RibbonDiagnostic {
  const RibbonDiagnostic({
    required this.message,
    required this.severity,
    this.line = 0,
    this.column = 0,
  });

  /// Human-readable description.
  final String message;

  /// How serious the problem is.
  final RibbonSeverity severity;

  /// 0-based line number.
  final int line;

  /// 0-based column number.
  final int column;

  @override
  String toString() =>
      '${severity.name.toUpperCase()} ${line + 1}:${column + 1} — $message';
}

/// The set of `itemType` tokens allowed at the item level.
const allowedItemTypes = {
  'large',
  'small',
  'dropdown',
  'splitbutton',
  'toggle',
  'checkbox',
  'separator',
};

/// Converts a character [offset] into a `(line, column)` pair.
({int line, int column}) _lineCol(String source, int offset) {
  if (offset <= 0) return (line: 0, column: 0);
  final clamped = offset > source.length ? source.length : offset;
  var line = 0;
  var col = 0;
  for (var i = 0; i < clamped; i++) {
    if (source.codeUnitAt(i) == 0x0A) {
      line++;
      col = 0;
    } else {
      col++;
    }
  }
  return (line: line, column: col);
}

/// Strictly validates a `.ribbon` JSON document, returning diagnostics.
///
/// Unlike [RibbonDefinition.fromJson] (which is intentionally lenient and
/// fills defaults), this walks the raw JSON tree and reports every structural
/// problem — the contract the LSP server and the designer both rely on.
List<RibbonDiagnostic> validateRibbonSource(String source) {
  final diagnostics = <RibbonDiagnostic>[];

  Object? root;
  try {
    root = jsonDecode(source);
  } on FormatException catch (e) {
    final pos = _lineCol(source, e.offset ?? 0);
    diagnostics.add(
      RibbonDiagnostic(
        message: 'Invalid JSON: ${e.message}',
        severity: RibbonSeverity.error,
        line: pos.line,
        column: pos.column,
      ),
    );
    return diagnostics;
  }

  if (root is! Map<String, dynamic>) {
    diagnostics.add(
      const RibbonDiagnostic(
        message: 'A .ribbon document must be a JSON object.',
        severity: RibbonSeverity.error,
      ),
    );
    return diagnostics;
  }

  final version = root['version'];
  if (version == null) {
    diagnostics.add(
      const RibbonDiagnostic(
        message: 'Missing "version" field (expected "2.0").',
        severity: RibbonSeverity.warning,
      ),
    );
  } else if (version != '2.0') {
    diagnostics.add(
      RibbonDiagnostic(
        message: 'Unsupported schema version "$version"; expected "2.0".',
        severity: RibbonSeverity.warning,
      ),
    );
  }

  final tabs = root['tabs'];
  if (tabs is! List) {
    diagnostics.add(
      const RibbonDiagnostic(
        message: '"tabs" must be an array.',
        severity: RibbonSeverity.error,
      ),
    );
    return diagnostics;
  }
  if (tabs.isEmpty) {
    diagnostics.add(
      const RibbonDiagnostic(
        message: '"tabs" is empty — the ribbon has no pages.',
        severity: RibbonSeverity.information,
      ),
    );
  }

  for (var ti = 0; ti < tabs.length; ti++) {
    final tab = tabs[ti];
    if (tab is! Map<String, dynamic>) {
      diagnostics.add(
        RibbonDiagnostic(
          message: 'tab[$ti] is not an object.',
          severity: RibbonSeverity.error,
        ),
      );
      continue;
    }
    _require(tab, 'caption', 'tab[$ti]', diagnostics);
    if (tab['isContextual'] == true &&
        (tab['contextGroup'] == null || tab['contextGroup'] == '')) {
      diagnostics.add(
        RibbonDiagnostic(
          message: 'tab[$ti] is contextual but has no "contextGroup".',
          severity: RibbonSeverity.warning,
        ),
      );
    }

    final groups = tab['groups'];
    if (groups is! List) {
      diagnostics.add(
        RibbonDiagnostic(
          message: 'tab[$ti] "groups" must be an array.',
          severity: RibbonSeverity.error,
        ),
      );
      continue;
    }
    for (var gi = 0; gi < groups.length; gi++) {
      final group = groups[gi];
      if (group is! Map<String, dynamic>) {
        diagnostics.add(
          RibbonDiagnostic(
            message: 'tab[$ti].groups[$gi] is not an object.',
            severity: RibbonSeverity.error,
          ),
        );
        continue;
      }
      _require(group, 'caption', 'tab[$ti].groups[$gi]', diagnostics);

      final items = group['items'];
      if (items is! List) {
        diagnostics.add(
          RibbonDiagnostic(
            message: 'tab[$ti].groups[$gi] "items" must be an array.',
            severity: RibbonSeverity.error,
          ),
        );
        continue;
      }
      for (var ii = 0; ii < items.length; ii++) {
        _validateItem(
          items[ii],
          'tab[$ti].groups[$gi].items[$ii]',
          diagnostics,
        );
      }
    }
  }

  return diagnostics;
}

void _validateItem(Object? raw, String path, List<RibbonDiagnostic> out) {
  if (raw is! Map<String, dynamic>) {
    out.add(
      RibbonDiagnostic(
        message: '$path is not an object.',
        severity: RibbonSeverity.error,
      ),
    );
    return;
  }
  final type = raw['itemType'];
  if (type == null) {
    out.add(
      RibbonDiagnostic(
        message: '$path is missing "itemType".',
        severity: RibbonSeverity.error,
      ),
    );
    return;
  }
  final typeStr = type.toString().toLowerCase();
  if (!allowedItemTypes.contains(typeStr)) {
    out.add(
      RibbonDiagnostic(
        message:
            '$path has unknown itemType "$type". Allowed: ${allowedItemTypes.join(', ')}.',
        severity: RibbonSeverity.error,
      ),
    );
    return;
  }
  if (typeStr != 'separator') {
    _require(raw, 'caption', path, out);
    _require(raw, 'tag', path, out);
  }
  if ((typeStr == 'dropdown' || typeStr == 'splitbutton') &&
      (raw['menuItems'] is! List)) {
    out.add(
      RibbonDiagnostic(
        message: '$path ($typeStr) has no "menuItems" array.',
        severity: RibbonSeverity.information,
      ),
    );
  }
}

void _require(
  Map<String, dynamic> obj,
  String field,
  String path,
  List<RibbonDiagnostic> out,
) {
  final value = obj[field];
  if (value == null || (value is String && value.isEmpty)) {
    out.add(
      RibbonDiagnostic(
        message: '$path is missing a "$field".',
        severity: RibbonSeverity.warning,
      ),
    );
  }
}
