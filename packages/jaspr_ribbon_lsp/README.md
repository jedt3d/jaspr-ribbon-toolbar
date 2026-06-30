# jaspr-ribbon-toolbar — `.ribbon` language server

`packages/jaspr_ribbon_lsp` is a Language Server Protocol server for `.ribbon`
JSON bundles (the format produced/consumed by the designer and rendered by the
`jaspr_ribbon_toolbar` component). It is built on
[`package:lsp_server`](https://pub.dev/packages/lsp_server).

## Features

- **Diagnostics** — `validateRibbonSource` is published as `textDocument/
  publishDiagnostics` on `didOpen` / `didChange` (Full sync): invalid JSON with
  line:column, missing `version`/`tabs`/`caption`/`tag`, unknown `itemType`,
  contextual tabs without `contextGroup`, dropdowns without `menuItems`.
- **Completion** — inside an `"itemType"` value: the 7 tokens; inside an
  `"iconKey"` value: every icon key referenced by the document (item keys + the
  embedded `icons` map).
- **Hover** — hover an `itemType` token to see its description + Xojo constant.
- **CLI** — `--validate-stdin` reads a document from stdin and prints
  diagnostics (used by `make lint-ribbon`).

## Run it

```bash
# LSP server over stdio (editors connect to this)
dart run packages/jaspr_ribbon_lsp/bin/jaspr_ribbon_lsp.dart

# one-shot CLI validator
dart run packages/jaspr_ribbon_lsp/bin/jaspr_ribbon_lsp.dart --validate-stdin < examples/explorer.ribbon
```

## Editor wire-up (VS Code)

A minimal extension scaffold lives in [`editors/vscode/`](../../editors/vscode).
From this repo:

```bash
cd editors/vscode
npm install
code .            # open the extension, press F5 to launch an Extension Development Host
```

Open any `*.ribbon` file → you get validation, autocomplete, and hover. The
server is launched with the `dart` on your `PATH` against
`packages/jaspr_ribbon_lsp/bin/jaspr_ribbon_lsp.dart`; override either via the
`jasprRibbonLsp.dartPath` / `jasprRibbonLsp.serverPath` settings.

To distribute: `npm install -g @vscode/vsce && vsce package` → install the
resulting `.vsix`.

## Reusing in the designer

The pure logic (`validateRibbonSource`, `suggestItemTypes`, `suggestIconKeys`,
`itemTypeDoc`) is in `package:jaspr_ribbon_lsp/jaspr_ribbon_lsp.dart` with **no
LSP transport dependency**, so the designer can reuse the same validator /
completions inside an embedded JSON editor without speaking LSP.
