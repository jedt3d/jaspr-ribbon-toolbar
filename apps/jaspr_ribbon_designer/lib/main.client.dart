/// Entrypoint for the **jaspr-ribbon-toolbar Designer**.
library;

import 'dart:async';

import 'package:jaspr/client.dart';

import 'app.dart';
import 'designer.dart';

void main() {
  runApp(const App());
  // The shell panels mount synchronously; start the imperative designer next tick.
  Future<void>.microtask(() => Designer().start());
}
