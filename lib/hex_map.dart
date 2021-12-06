import 'package:flutter/material.dart';

import 'ui/hex_map_ui.dart';

class HexMap extends StatelessWidget {
  const HexMap({final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Hex Map',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const HexMapUi(),
      // Hide the annoying debug ribbon, it covers the settings icon.
      debugShowCheckedModeBanner: false,
    );
  }
}
