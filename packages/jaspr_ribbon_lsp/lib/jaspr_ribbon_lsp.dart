/// A Language Server Protocol server for `.ribbon` bundles.
///
/// Re-exports the strict validator and the language helpers (completion,
/// hover) so they can be reused by the designer and by tests without depending
/// on the LSP transport.
library;

export 'src/ribbon_language.dart';
export 'src/ribbon_validator.dart';
