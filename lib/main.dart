import 'dart:html';
import 'package:flutter/material.dart';

import 'map.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  removeFlutterLoader();
  runApp(const Map());
}

void removeFlutterLoader() {
  document.dispatchEvent(Event('dart-app-ready'));
}

