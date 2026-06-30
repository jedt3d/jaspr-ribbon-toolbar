// Minimal VS Code language client for the jaspr-ribbon-toolbar .ribbon LSP.
// Spawns the Dart server over stdio and wires VS Code's diagnostics /
// completion / hover to it.
const path = require('path');
const vscode = require('vscode');
const { LanguageClient, TransportKind } = require('vscode-languageclient');

let client;

function activate(context) {
  const cfg = vscode.workspace.getConfiguration('jasprRibbonLsp');
  const dart = cfg.get('dartPath', 'dart');
  // Default to this repo's server script; override via the setting.
  const defaultServer = path.join(context.extensionPath, '..', '..', 'packages', 'jaspr_ribbon_lsp', 'bin', 'jaspr_ribbon_lsp.dart');
  const serverPath = cfg.get('serverPath') || defaultServer;

  const serverOptions = {
    run: { command: dart, args: ['run', serverPath], transport: TransportKind.stdio },
    debug: { command: dart, args: ['run', serverPath], transport: TransportKind.stdio },
  };

  const clientOptions = {
    documentSelector: [{ scheme: 'file', language: 'ribbon' }],
  };

  client = new LanguageClient('jasprRibbonLsp', 'jaspr-ribbon-toolbar LSP', serverOptions, clientOptions);
  client.start();
}

function deactivate() {
  return client?.stop();
}

module.exports = { activate, deactivate };
