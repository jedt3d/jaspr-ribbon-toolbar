import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:lsp_server/lsp_server.dart';

import 'package:jaspr_ribbon_lsp/jaspr_ribbon_lsp.dart';

/// Entry point for the `.ribbon` language server.
///
/// Over stdio it speaks the Language Server Protocol: publishes
/// `validateRibbonSource` diagnostics on open/edit, and answers
/// `textDocument/completion` (itemType / iconKey) and `textDocument/hover`
/// (itemType docs). `--validate-stdin` is a CLI escape hatch used by the
/// Makefile `lint-ribbon` target.
Future<void> main(List<String> args) async {
  if (args.contains('--validate-stdin')) {
    await _runCliValidator();
    return;
  }

  final connection = Connection(stdin, stdout);
  final docs = <String, String>{}; // uri → full text

  connection.onInitialize((InitializeParams params) async {
    return InitializeResult(
      capabilities: ServerCapabilities(
        textDocumentSync: const Either2.t1(TextDocumentSyncKind.Full),
        completionProvider: CompletionOptions(triggerCharacters: ['"', '.']),
        hoverProvider: const Either2.t1(true),
      ),
    );
  });

  connection.onDidOpenTextDocument((DidOpenTextDocumentParams params) async {
    final uri = params.textDocument.uri.toString();
    if (!_isRibbon(uri)) return;
    docs[uri] = params.textDocument.text;
    _publish(connection, uri, params.textDocument.text);
  });

  connection.onDidChangeTextDocument((
    DidChangeTextDocumentParams params,
  ) async {
    final uri = params.textDocument.uri.toString();
    if (!_isRibbon(uri)) return;
    // Full sync: the whole document arrives in the first change event. The
    // change is an Either2 (range vs full); both variants carry `.text`.
    if (params.contentChanges.isNotEmpty) {
      docs[uri] = params.contentChanges.first.map(
        (e1) => e1.text,
        (e2) => e2.text,
      );
      _publish(connection, uri, docs[uri]!);
    }
  });

  connection.onDidCloseTextDocument((DidCloseTextDocumentParams params) async {
    final uri = params.textDocument.uri.toString();
    docs.remove(uri);
    // Clear diagnostics for the closed document.
    connection.sendDiagnostics(
      PublishDiagnosticsParams(
        uri: params.textDocument.uri,
        diagnostics: const [],
      ),
    );
  });

  connection.onCompletion((TextDocumentPositionParams params) async {
    final uri = params.textDocument.uri.toString();
    final text = docs[uri];
    if (text == null)
      return CompletionList(isIncomplete: false, items: const []);
    final line = _line(text, params.position.line);
    final ctx = detectFieldContext(line, params.position.character);
    switch (ctx) {
      case FieldContext.itemType:
        return CompletionList(
          isIncomplete: false,
          items: [
            for (final t in suggestItemTypes())
              CompletionItem(
                label: t,
                kind: CompletionItemKind.Value,
                detail: itemTypeDoc(t),
                insertText: t,
              ),
          ],
        );
      case FieldContext.iconKey:
        return CompletionList(
          isIncomplete: false,
          items: [
            for (final k in suggestIconKeys(text))
              CompletionItem(
                label: k,
                kind: CompletionItemKind.Value,
                insertText: k,
              ),
          ],
        );
      case FieldContext.other:
        return CompletionList(isIncomplete: false, items: const []);
    }
  });

  // Hover is registered directly so we can return `null` ("no hover") —
  // `onHover`'s handler is typed `Future<Hover>` (non-nullable).
  connection.peer.registerMethod('textDocument/hover', (
    rpc.Parameters params,
  ) async {
    final p = TextDocumentPositionParams.fromJson(
      params.value as Map<String, Object?>,
    );
    final uri = p.textDocument.uri.toString();
    final text = docs[uri];
    if (text == null) return null;
    final line = _line(text, p.position.line);
    final word = wordAt(line, p.position.character);
    final doc = itemTypeDoc(word);
    if (doc == null) return null;
    return Hover(
      contents: Either2<MarkupContent, String>.t1(
        MarkupContent(kind: MarkupKind.Markdown, value: '**$word** — $doc'),
      ),
    );
  });

  await connection.listen();
}

bool _isRibbon(String uri) => uri.endsWith('.ribbon') || uri.endsWith('.json');

String _line(String text, int line) {
  final lines = text.split('\n');
  return (line >= 0 && line < lines.length) ? lines[line] : '';
}

void _publish(Connection connection, String uri, String text) {
  final diags = <Diagnostic>[];
  final lines = text.split('\n');
  for (final d in validateRibbonSource(text)) {
    final lineLen = (d.line >= 0 && d.line < lines.length)
        ? lines[d.line].length
        : 0;
    diags.add(
      Diagnostic(
        range: Range(
          start: Position(line: d.line, character: d.column),
          end: Position(
            line: d.line,
            character: d.column < lineLen ? lineLen : d.column + 1,
          ),
        ),
        severity: _severity(d.severity),
        source: 'xjribbon',
        message: d.message,
      ),
    );
  }
  connection.sendDiagnostics(
    PublishDiagnosticsParams(uri: Uri.parse(uri), diagnostics: diags),
  );
}

DiagnosticSeverity _severity(RibbonSeverity s) => switch (s) {
  RibbonSeverity.error => DiagnosticSeverity.Error,
  RibbonSeverity.warning => DiagnosticSeverity.Warning,
  RibbonSeverity.information => DiagnosticSeverity.Information,
  RibbonSeverity.hint => DiagnosticSeverity.Hint,
};

/// `--validate-stdin` CLI mode: reads a `.ribbon` document from stdin and prints
/// diagnostics to stdout, exiting non-zero on errors.
Future<void> _runCliValidator() async {
  final source = await stdin.transform(const SystemEncoding().decoder).join();
  final diagnostics = validateRibbonSource(source);
  if (diagnostics.isEmpty) {
    // ignore: avoid_print
    print('OK — .ribbon document is valid.');
    exit(0);
  }
  for (final d in diagnostics) {
    // ignore: avoid_print
    print(d);
  }
  exit(diagnostics.any((d) => d.severity == RibbonSeverity.error) ? 1 : 0);
}
