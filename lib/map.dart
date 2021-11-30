import 'package:flutter/material.dart';

import 'map_ui.dart';

class Map extends StatelessWidget {
  const Map({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const MapUI(),
      // Hide the annoying debug ribbon, it covers the settings icon.
      debugShowCheckedModeBanner: false,
    );
  }
}
